output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.auto_healing_eks.cluster_id
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = module.auto_healing_eks.cluster_arn
}

output "cluster_endpoint" {
  description = "The endpoint URL for the EKS cluster API server"
  value       = module.auto_healing_eks.cluster_endpoint
}

output "node_group_ids" {
  description = "Map of node group names to their IDs"
  value       = module.auto_healing_eks.node_group_ids
}

output "karpenter_role_arn" {
  description = "ARN of the IAM role used by Karpenter"
  value       = module.auto_healing_eks.karpenter_role_arn
}

output "remediation_lambda_arn" {
  description = "ARN of the node remediation Lambda function"
  value       = module.auto_healing_eks.remediation_lambda_arn
}
