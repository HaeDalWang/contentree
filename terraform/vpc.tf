#---------------------------------------------------------------
# VPC 생성
#---------------------------------------------------------------

module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  version         = "~> 3.0"
  name            = local.name
  cidr            = "10.150.0.0/16"
  azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnets  = ["10.150.44.0/24"]
  private_subnets = ["10.150.46.0/24"]

  ## NAT 대신 Squid로 아웃바운드 프록시 구현
  #enable_nat_gateway   = true
  #single_nat_gateway   = true
  enable_dns_hostnames = true

  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  tags = local.tags
}

#---------------------------------------------------------------
# ENI
# pri: master2, ha1 ,worker3(app,infra,storage), jenkins,Harbor1
# pub: squidproxy1, ingressnode1
#---------------------------------------------------------------

resource "aws_network_interface" "master1" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.150.46.16"]
}
resource "aws_network_interface" "master2" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.150.46.17"]
}
resource "aws_network_interface" "ha1" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.150.46.30"]
}
resource "aws_network_interface" "worker1" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.150.46.19"]
}
resource "aws_network_interface" "worker2" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.150.46.20"]
}
resource "aws_network_interface" "worker3" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.150.46.21"]
}
resource "aws_network_interface" "ci" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.150.46.32"]
}
resource "aws_network_interface" "squid" {
  subnet_id   = module.vpc.public_subnets[0]
  private_ips = ["10.150.44.18"]
}
resource "aws_network_interface" "ingress" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.150.44.16"]
}