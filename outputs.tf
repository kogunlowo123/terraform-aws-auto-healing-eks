output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "The endpoint URL for the EKS cluster API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "node_group_ids" {
  description = "Map of node group names to their IDs"
  value       = { for k, v in aws_eks_node_group.this : k => v.id }
}

output "karpenter_role_arn" {
  description = "ARN of the IAM role used by Karpenter"
  value       = var.enable_karpenter ? aws_iam_role.karpenter[0].arn : null
}

output "remediation_lambda_arn" {
  description = "ARN of the node remediation Lambda function"
  value       = var.enable_auto_remediation ? aws_lambda_function.node_remediation[0].arn : null
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  value       = aws_iam_openid_connect_provider.eks.arn
}
