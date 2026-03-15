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
