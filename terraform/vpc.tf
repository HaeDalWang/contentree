module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  version = "6.5.1" # 최신화 2025년 12월 11일

  name            = local.project
  cidr            = "10.233.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnets  = ["10.233.10.0/24"]
  private_subnets = ["10.233.100.0/24"]

  ## NAT 대신 Squid로 아웃바운드 프록시 구현
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  default_security_group_egress = [
    {
      cidr_blocks      = "0.0.0.0/0"
      ipv6_cidr_blocks = "::/0"
    }
  ]

  tags = local.tags
}

resource "aws_network_interface" "master1" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.233.100.10"]
  security_groups = [aws_security_group.kubernetes.id]  
}
resource "aws_network_interface" "worker1" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.233.100.20"]
  security_groups = [aws_security_group.kubernetes.id]  
}
resource "aws_network_interface" "worker2" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.233.100.21"]
  security_groups = [aws_security_group.kubernetes.id]  
}
resource "aws_network_interface" "ingress" {
  subnet_id   = module.vpc.public_subnets[0]
  private_ips = ["10.233.10.15"]
  security_groups = [aws_security_group.kubernetes.id]  
}

#---------------------------------------------------------------
# 보안그룹 셋팅 ~ 
#---------------------------------------------------------------

resource "aws_security_group" "kubernetes" {
  name_prefix = "kubernetes-"
  description = "Security group for Kubernetes cluster (kubespray)"
  vpc_id      = module.vpc.vpc_id

  # SSH 접근
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP/HTTPS
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API Server
  ingress {
    description = "Kubernetes API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # etcd client/server
  ingress {
    description = "etcd client/server"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  # kubelet API
  ingress {
    description = "kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  # kube-scheduler
  ingress {
    description = "kube-scheduler"
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  # kube-controller-manager
  ingress {
    description = "kube-controller-manager"
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  # NodePort 서비스 범위
  ingress {
    description = "NodePort Services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Calico BGP (bird 백엔드)
  ingress {
    description = "Calico BGP"
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  # Calico IPIP (protocol 4)
  ingress {
    description = "Calico IPIP"
    from_port   = 0
    to_port     = 0
    protocol    = "4"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  # VPC 내부 전체 통신 (클러스터 내부 통신용)
  ingress {
    description = "VPC internal communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
  ingress {
    description = "VPC internal communication (UDP)"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  tags = merge(local.tags, {
    Name = "kubernetes-sg"
  })
}

resource "aws_security_group_rule" "kubernetes_egress" {
  security_group_id = aws_security_group.kubernetes.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}