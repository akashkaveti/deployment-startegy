provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {
    
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "eks-vpc"
  cidr =  "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.64.0/18", "10.0.128.0/18", "10.0.192.0/18"]
  public_subnets  = ["10.0.0.0/21", "10.0.8.0/21", "10.0.16.0/21"]

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.identifier}" = "shared"
    "kubernetes.io/role/elb"                    = 1
    "tier"                                      = "eks-public-subnet"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.identifier}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
    "tier"                                      = "eks-private-subnet"
  }
  tags = {}
}