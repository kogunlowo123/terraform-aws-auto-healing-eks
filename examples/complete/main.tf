################################################################################
# Auto-Healing EKS - Complete Example
################################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "eks-auto-healing-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "auto_healing_eks" {
  source = "../../"

  cluster_name    = "production-eks"
  cluster_version = "1.29"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  node_groups = [
    {
      name           = "general"
      instance_types = ["m5.xlarge"]
      min_size       = 3
      max_size       = 20
      desired_size   = 5
      disk_size      = 100
      capacity_type  = "ON_DEMAND"
      labels = {
        workload = "general"
      }
    },
    {
      name           = "compute"
      instance_types = ["c5.2xlarge"]
      min_size       = 2
      max_size       = 15
      desired_size   = 3
      disk_size      = 50
      capacity_type  = "SPOT"
      labels = {
        workload = "compute-intensive"
      }
      taints = [
        {
          key    = "workload"
          value  = "compute"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  ]

  enable_karpenter                = true
  enable_cluster_autoscaler       = false
  enable_node_termination_handler = true
  enable_auto_remediation         = true
  remediation_lambda_timeout      = 300
  alarm_evaluation_periods        = 3
  alarm_threshold                 = 1

  tags = {
    Project     = "production-platform"
    Environment = "production"
    Team        = "platform-engineering"
  }
}
