terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Remote state in the Phase 0 bucket.
  backend "s3" {
    bucket       = "bookstore-tfstate-016257615899"
    key          = "eks/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}

# Read the VPC we built in Phase 2 directly from its remote state.
# This is how one stack borrows another stack's outputs without copy-pasting IDs.
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "bookstore-tfstate-016257615899"
    key    = "vpc/terraform.tfstate"
    region = "us-west-2"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.project}-eks"
  kubernetes_version = var.kubernetes_version

  # Make the cluster API reachable from your laptop, and add your IAM user
  # as a cluster admin so kubectl works right after apply.
  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true

  # Build inside the Phase 2 VPC. Nodes run in the PRIVATE subnets.
  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  # The worker machines that actually run your containers.
  eks_managed_node_groups = {
    general = {
      instance_types = [var.node_instance_type]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }

   addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  tags = {
    Project   = var.project
    ManagedBy = "terraform"
  }
}


