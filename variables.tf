variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "Cluster name must start with a letter and contain only alphanumeric characters and hyphens."
  }
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"

  validation {
    condition     = can(regex("^1\\.(2[7-9]|3[0-9])$", var.cluster_version))
    error_message = "Cluster version must be a valid EKS Kubernetes version (1.27+)."
  }
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC identifier."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster (minimum 2 subnets in different AZs)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs are required for high availability."
  }
}

variable "node_groups" {
  description = "List of managed node group configurations"
  type = list(object({
    name           = string
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = optional(number, 50)
    capacity_type  = optional(string, "ON_DEMAND")
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = [
    {
      name           = "default"
      instance_types = ["m5.large"]
      min_size       = 2
      max_size       = 10
      desired_size   = 3
    }
  ]

  validation {
    condition     = length(var.node_groups) > 0
    error_message = "At least one node group must be defined."
  }
}

variable "enable_karpenter" {
  description = "Enable Karpenter for intelligent node auto-provisioning"
  type        = bool
  default     = true
}

variable "enable_cluster_autoscaler" {
  description = "Enable Kubernetes Cluster Autoscaler"
  type        = bool
  default     = false
}

variable "enable_node_termination_handler" {
  description = "Enable AWS Node Termination Handler for graceful spot instance handling"
  type        = bool
  default     = true
}

variable "enable_auto_remediation" {
  description = "Enable automated node remediation via Lambda and EventBridge"
  type        = bool
  default     = true
}

variable "remediation_lambda_timeout" {
  description = "Timeout in seconds for the node remediation Lambda function"
  type        = number
  default     = 300

  validation {
    condition     = var.remediation_lambda_timeout >= 30 && var.remediation_lambda_timeout <= 900
    error_message = "Lambda timeout must be between 30 and 900 seconds."
  }
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for CloudWatch node health alarms"
  type        = number
  default     = 3

  validation {
    condition     = var.alarm_evaluation_periods >= 1 && var.alarm_evaluation_periods <= 10
    error_message = "Alarm evaluation periods must be between 1 and 10."
  }
}

variable "alarm_threshold" {
  description = "Threshold for CloudWatch node health alarms (percentage)"
  type        = number
  default     = 1

  validation {
    condition     = var.alarm_threshold >= 0 && var.alarm_threshold <= 100
    error_message = "Alarm threshold must be between 0 and 100."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
