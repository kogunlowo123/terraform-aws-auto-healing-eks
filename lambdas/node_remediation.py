"""
EKS Node Remediation Lambda Function

Automatically remediates unhealthy EKS worker nodes by:
1. Detecting EC2 status check failures via EventBridge
2. Attempting a reboot of the unhealthy instance
3. If reboot fails, terminating the instance and letting the ASG replace it
4. Sending notifications via SNS
"""

import json
import logging
import os
import time

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2_client = boto3.client("ec2")
autoscaling_client = boto3.client("autoscaling")
eks_client = boto3.client("eks")
sns_client = boto3.client("sns")

CLUSTER_NAME = os.environ.get("CLUSTER_NAME", "")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "")
REBOOT_WAIT_SECONDS = 120
MAX_REBOOT_ATTEMPTS = 2


def lambda_handler(event, context):
    """Main Lambda handler for node remediation events."""
    logger.info("Received event: %s", json.dumps(event))

    detail_type = event.get("detail-type", "")
    detail = event.get("detail", {})

    if detail_type == "EC2 Instance State-change Notification":
        instance_id = detail.get("instance-id", "")
        state = detail.get("state", "")
        handle_state_change(instance_id, state)
    elif detail_type == "AWS Health Event":
        handle_health_event(detail)
    else:
        logger.warning("Unhandled event type: %s", detail_type)

    return {"statusCode": 200, "body": "Remediation check complete"}


def handle_state_change(instance_id, state):
    """Handle EC2 instance state change events."""
    if not instance_id:
        logger.error("No instance ID provided in event")
        return

    if not is_cluster_node(instance_id):
        logger.info("Instance %s is not part of cluster %s, skipping", instance_id, CLUSTER_NAME)
        return

    logger.info("Processing state change for instance %s: %s", instance_id, state)

    if state in ("stopping", "stopped"):
        send_notification(
            subject=f"EKS Node State Change: {instance_id}",
            message=(
                f"Instance {instance_id} in cluster {CLUSTER_NAME} has entered "
                f"state '{state}'. The Auto Scaling group will handle replacement."
            ),
        )


def handle_health_event(detail):
    """Handle AWS Health events related to EC2 instances."""
    affected_entities = detail.get("affectedEntities", [])

    for entity in affected_entities:
        instance_id = entity.get("entityValue", "")
        if not instance_id or not instance_id.startswith("i-"):
            continue

        if not is_cluster_node(instance_id):
            continue

        logger.info("Health event affects cluster node: %s", instance_id)
        remediate_node(instance_id)


def is_cluster_node(instance_id):
    """Check if an EC2 instance belongs to the EKS cluster."""
    try:
        response = ec2_client.describe_instances(InstanceIds=[instance_id])
        reservations = response.get("Reservations", [])

        if not reservations:
            return False

        instance = reservations[0]["Instances"][0]
        tags = {tag["Key"]: tag["Value"] for tag in instance.get("Tags", [])}

        cluster_tag = f"kubernetes.io/cluster/{CLUSTER_NAME}"
        return cluster_tag in tags

    except ClientError as e:
        logger.error("Error checking instance %s: %s", instance_id, str(e))
        return False


def remediate_node(instance_id):
    """Attempt to remediate an unhealthy node."""
    logger.info("Starting remediation for instance %s", instance_id)

    for attempt in range(1, MAX_REBOOT_ATTEMPTS + 1):
        logger.info("Reboot attempt %d for instance %s", attempt, instance_id)

        try:
            ec2_client.reboot_instances(InstanceIds=[instance_id])
            logger.info("Reboot command sent for instance %s", instance_id)

            time.sleep(REBOOT_WAIT_SECONDS)

            status = get_instance_status(instance_id)
            if status == "ok":
                logger.info("Instance %s recovered after reboot", instance_id)
                send_notification(
                    subject=f"EKS Node Recovered: {instance_id}",
                    message=f"Instance {instance_id} in cluster {CLUSTER_NAME} recovered after reboot (attempt {attempt}).",
                )
                return

        except ClientError as e:
            logger.error("Failed to reboot instance %s: %s", instance_id, str(e))

    logger.warning("Instance %s did not recover after %d reboot attempts, terminating", instance_id, MAX_REBOOT_ATTEMPTS)
    terminate_and_replace(instance_id)


def get_instance_status(instance_id):
    """Get the status check result for an instance."""
    try:
        response = ec2_client.describe_instance_status(InstanceIds=[instance_id])
        statuses = response.get("InstanceStatuses", [])

        if not statuses:
            return "unknown"

        instance_status = statuses[0]["InstanceStatus"]["Status"]
        system_status = statuses[0]["SystemStatus"]["Status"]

        if instance_status == "ok" and system_status == "ok":
            return "ok"
        return "impaired"

    except ClientError as e:
        logger.error("Error getting status for instance %s: %s", instance_id, str(e))
        return "unknown"


def terminate_and_replace(instance_id):
    """Terminate an unhealthy instance and let ASG replace it."""
    try:
        asg_name = get_asg_for_instance(instance_id)

        if asg_name:
            autoscaling_client.terminate_instance_in_auto_scaling_group(
                InstanceId=instance_id,
                ShouldDecrementDesiredCapacity=False,
            )
            logger.info("Terminated instance %s in ASG %s (replacement will be launched)", instance_id, asg_name)

            send_notification(
                subject=f"EKS Node Terminated and Replacing: {instance_id}",
                message=(
                    f"Instance {instance_id} in cluster {CLUSTER_NAME} was terminated "
                    f"after failed remediation attempts. ASG {asg_name} will launch a replacement."
                ),
            )
        else:
            logger.warning("Could not find ASG for instance %s, terminating directly", instance_id)
            ec2_client.terminate_instances(InstanceIds=[instance_id])

    except ClientError as e:
        logger.error("Failed to terminate instance %s: %s", instance_id, str(e))
        send_notification(
            subject=f"EKS Node Remediation FAILED: {instance_id}",
            message=f"Failed to terminate unhealthy instance {instance_id} in cluster {CLUSTER_NAME}: {str(e)}",
        )


def get_asg_for_instance(instance_id):
    """Find the Auto Scaling group that an instance belongs to."""
    try:
        response = autoscaling_client.describe_auto_scaling_groups()

        for asg in response.get("AutoScalingGroups", []):
            for instance in asg.get("Instances", []):
                if instance["InstanceId"] == instance_id:
                    return asg["AutoScalingGroupName"]

        return None

    except ClientError as e:
        logger.error("Error finding ASG for instance %s: %s", instance_id, str(e))
        return None


def send_notification(subject, message):
    """Send an SNS notification."""
    if not SNS_TOPIC_ARN:
        logger.warning("No SNS topic configured, skipping notification")
        return

    try:
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject[:100],
            Message=message,
        )
        logger.info("Notification sent: %s", subject)
    except ClientError as e:
        logger.error("Failed to send notification: %s", str(e))
