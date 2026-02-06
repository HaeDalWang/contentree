# k8s/분석.md 노드 영역 기준: 10.150.46.x (CP/Worker), 10.150.44.x (Router)
# POC: CP 3대(mvd-kubecp01~03), Worker 3대(mvd-kubewk01~03), Ingress 1대(mvd-kubert01)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"

  name = local.project
  cidr = "10.150.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  # 라우터(Ingress): 10.150.44.x 대역 (고객과 동일)
  public_subnets  = ["10.150.44.0/24"]
  # CP/Worker/인프라/스토리지/HAProxy: 10.150.46.x 대역 (고객과 동일)
  private_subnets = ["10.150.46.0/24"]

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

# Control Plane 3대 — 인벤토리: mvd-kubecp01~03 = 10.150.46.16~18
resource "aws_network_interface" "mvd_kubecp01" {
  subnet_id       = module.vpc.private_subnets[0]
  private_ips     = ["10.150.46.16"]
  security_groups = [aws_security_group.kubernetes.id]
}
resource "aws_network_interface" "mvd_kubecp02" {
  subnet_id       = module.vpc.private_subnets[0]
  private_ips     = ["10.150.46.17"]
  security_groups = [aws_security_group.kubernetes.id]
}
resource "aws_network_interface" "mvd_kubecp03" {
  subnet_id       = module.vpc.private_subnets[0]
  private_ips     = ["10.150.46.18"]
  security_groups = [aws_security_group.kubernetes.id]
}

# Worker 3대 — 인벤토리: mvd-kubewk01~03 = 10.150.46.19~21
resource "aws_network_interface" "mvd_kubewk01" {
  subnet_id       = module.vpc.private_subnets[0]
  private_ips     = ["10.150.46.19"]
  security_groups = [aws_security_group.kubernetes.id]
}
resource "aws_network_interface" "mvd_kubewk02" {
  subnet_id       = module.vpc.private_subnets[0]
  private_ips     = ["10.150.46.20"]
  security_groups = [aws_security_group.kubernetes.id]
}
resource "aws_network_interface" "mvd_kubewk03" {
  subnet_id       = module.vpc.private_subnets[0]
  private_ips     = ["10.150.46.21"]
  security_groups = [aws_security_group.kubernetes.id]
}

# Ingress(Router) 1대 — 인벤토리: mvd-kubert01 = 10.150.44.16
resource "aws_network_interface" "mvd_kubert01" {
  subnet_id       = module.vpc.public_subnets[0]
  private_ips     = ["10.150.44.16"]
  security_groups = [aws_security_group.kubernetes.id]
}

#---------------------------------------------------------------
# 보안그룹 (Kubernetes / Calico / etcd / kubelet 등)
#---------------------------------------------------------------
resource "aws_security_group" "kubernetes" {
  name_prefix = "k8s-poc-"
  description = "Kubernetes POC (kubespray minimal, k8s node CIDR aligned)"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  tags = merge(local.tags, { Name = "kubernetes-poc-sg" })
}

resource "aws_security_group_rule" "kubernetes_internal" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.kubernetes.id
  security_group_id        = aws_security_group.kubernetes.id
  description              = "Security group internal"
}

resource "aws_security_group_rule" "kubernetes_api" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.kubernetes.id
  security_group_id        = aws_security_group.kubernetes.id
  description              = "Kubernetes API"
}

resource "aws_security_group_rule" "etcd" {
  type                     = "ingress"
  from_port                = 2379
  to_port                  = 2380
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.kubernetes.id
  security_group_id        = aws_security_group.kubernetes.id
  description              = "etcd"
}

resource "aws_security_group_rule" "kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.kubernetes.id
  security_group_id        = aws_security_group.kubernetes.id
  description              = "kubelet"
}

resource "aws_security_group_rule" "kube_scheduler" {
  type                     = "ingress"
  from_port                = 10259
  to_port                  = 10259
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.kubernetes.id
  security_group_id        = aws_security_group.kubernetes.id
  description              = "kube-scheduler"
}

resource "aws_security_group_rule" "kube_controller_manager" {
  type                     = "ingress"
  from_port                = 10257
  to_port                  = 10257
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.kubernetes.id
  security_group_id        = aws_security_group.kubernetes.id
  description              = "kube-controller-manager"
}

resource "aws_security_group_rule" "nodeport" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.kubernetes.id
  security_group_id        = aws_security_group.kubernetes.id
  description              = "NodePort"
}

resource "aws_security_group_rule" "calico_bgp" {
  type                     = "ingress"
  from_port                = 179
  to_port                  = 179
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.kubernetes.id
  security_group_id        = aws_security_group.kubernetes.id
  description              = "Calico BGP"
}

resource "aws_security_group_rule" "kubernetes_egress" {
  security_group_id = aws_security_group.kubernetes.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
