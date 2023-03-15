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
# 노드들이 사용 할 ENI 생성
#---------------------------------------------------------------

