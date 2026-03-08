# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-15

### Added

- EKS cluster provisioning with full control plane logging (api, audit, authenticator, controllerManager, scheduler)
- Managed node groups with configurable instance types, scaling, labels, and taints
- Launch templates with encrypted EBS volumes and IMDSv2 enforcement
- EKS managed addons: CoreDNS, kube-proxy, VPC CNI, EBS CSI driver
- Karpenter integration for intelligent node auto-provisioning with SQS interruption queue
- Cluster Autoscaler Helm deployment with IRSA
- AWS Node Termination Handler for graceful spot instance draining
- Metrics Server deployment for HPA and VPA support
- OIDC provider for IAM Roles for Service Accounts (IRSA)
- CloudWatch metric alarms for EC2 status check failures per node group
- Auto-scaling policies (scale-in and scale-out) for managed node groups
- Lambda-based node remediation triggered by EventBridge rules
- EventBridge rules for EC2 state changes and AWS Health events
- SNS topic for node health alert notifications
- Security groups for cluster control plane and worker nodes with least-privilege rules
- Comprehensive IAM roles and policies for cluster, nodes, Karpenter, Cluster Autoscaler, and Lambda
