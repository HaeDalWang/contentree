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
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  tags = local.tags
}
## NAT를 대신할 squid 프록시 라우팅 규칙
# resource "aws_route_table" "squid-proxy" {
#   vpc_id = module.vpc.vpc_id

#   route {
#     cidr_block = "0.0.0.0/0"
#     network_interface_id = aws_network_interface.squid.id
#   }
#   tags = {
#     Name = "squid"
#   }
# }

# resource "aws_route_table_association" "squid-proxy" {
#   subnet_id      = module.vpc.private_subnets[0]
#   route_table_id = aws_route_table.squid-proxy.id
# }

#---------------------------------------------------------------
# ENI
# pri: master2, ha1 ,worker3(app,infra,storage), jenkins,Harbor1
# pub: squidproxy1, ingressnode1
#---------------------------------------------------------------

resource "aws_network_interface" "master1" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.150.46.16"]
  security_groups = [aws_security_group.kubernetes.id]  
}
# resource "aws_network_interface" "master2" {
#   subnet_id   = module.vpc.private_subnets[0]
#   private_ips = ["10.150.46.17"]
#   security_groups = [aws_security_group.kubernetes.id]  
# }
resource "aws_network_interface" "ha1" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.150.46.30"]
  security_groups = [aws_security_group.kubernetes.id]  
}
resource "aws_network_interface" "worker1" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.150.46.19"]
  security_groups = [aws_security_group.kubernetes.id]  
}
resource "aws_network_interface" "worker2" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.150.46.20"]
  security_groups = [aws_security_group.kubernetes.id]  
}
resource "aws_network_interface" "worker3" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.150.46.21"]
  security_groups = [aws_security_group.kubernetes.id]  
}
resource "aws_network_interface" "ci" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.150.46.32"]
  security_groups = [aws_security_group.kubernetes.id]  
}
resource "aws_network_interface" "squid" {
  subnet_id   = module.vpc.public_subnets[0]
  private_ips = ["10.150.44.18"]
  security_groups = [aws_security_group.kubernetes.id]  
}
resource "aws_network_interface" "ingress" {
  subnet_id   = module.vpc.public_subnets[0]
  private_ips = ["10.150.44.16"]
  security_groups = [aws_security_group.kubernetes.id]  
}

#---------------------------------------------------------------
# 보안그룹 셋팅 ~ 
#---------------------------------------------------------------

resource "aws_security_group" "kubernetes" {
  name_prefix = "kubernetes-"
  description = "Security group for Kubernetes cluster"
  vpc_id      =  module.vpc.vpc_id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 10250
    to_port     = 10255
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "kubernetes_egress" {
  security_group_id = aws_security_group.kubernetes.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}