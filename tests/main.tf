module "auto_healing_eks" {
  source = "../"

  cluster_name    = "test-eks-cluster"
  cluster_version = "1.29"
  vpc_id          = "vpc-0123456789abcdef0"
  subnet_ids      = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  node_groups = [
    {
      name           = "default"
      instance_types = ["m5.large"]
      min_size       = 2
      max_size       = 10
      desired_size   = 3
    }
  ]

  enable_karpenter                = false
  enable_cluster_autoscaler       = false
  enable_node_termination_handler = true
  enable_auto_remediation         = true
  remediation_lambda_timeout      = 300
  alarm_evaluation_periods        = 3
  alarm_threshold                 = 1

  tags = {
    Environment = "test"
    ManagedBy   = "terraform"
  }
}
