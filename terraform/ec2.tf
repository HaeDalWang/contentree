## Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu_24_lts" {
  most_recent = true
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

#---------------------------------------------------------------
#  앤서블용 베스쳔 인스턴스 및 보안그룹 생성
#---------------------------------------------------------------
# Key페어 
data "aws_key_pair" "ansible" {
  key_name = "saltware"
}

## ansible controller Instance 
resource "aws_instance" "ansible-controller" {
  ami                         = data.aws_ami.ubuntu_24_lts.id
  instance_type               = "t3.small"
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = data.aws_key_pair.ansible.key_name
  associate_public_ip_address = true # 자동 퍼블릭 IP 할당 활성화
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  vpc_security_group_ids      = [aws_security_group.kubernetes.id]

  user_data = <<-EOF
    #!/bin/bash
    # SSM Agent 설치 및 시작
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  tags = merge(local.tags, {
    Name = "ansible-controller"
    Role = "ansible-controller"
  })
}

#---------------------------------------------------------------
#  Kubernetes 클러스터 인스턴스 생성
#  구성: 1 master, 2 worker, 1 ingress
#---------------------------------------------------------------

## Master Node (Control Plane)
resource "aws_instance" "master1" {
  ami                  = data.aws_ami.ubuntu_24_lts.id
  instance_type        = "t3.medium"
  key_name             = data.aws_key_pair.ansible.key_name
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    # SSM Agent 설치 및 시작
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  primary_network_interface {
    network_interface_id = aws_network_interface.master1.id
  }

  tags = merge(local.tags, {
    Name = "k8s-master-1"
    Role = "master"
  })
}

## Worker Nodes
resource "aws_instance" "worker1" {
  ami                  = data.aws_ami.ubuntu_24_lts.id
  instance_type        = "t3.medium"
  key_name             = data.aws_key_pair.ansible.key_name
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    # SSM Agent 설치 및 시작
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  primary_network_interface {
    network_interface_id = aws_network_interface.worker1.id
  }

  tags = merge(local.tags, {
    Name = "k8s-worker-1"
    Role = "worker"
  })
}

resource "aws_instance" "worker2" {
  ami                  = data.aws_ami.ubuntu_24_lts.id
  instance_type        = "t3.medium"
  key_name             = data.aws_key_pair.ansible.key_name
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    # SSM Agent 설치 및 시작
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  primary_network_interface {
    network_interface_id = aws_network_interface.worker2.id
  }

  tags = merge(local.tags, {
    Name = "k8s-worker-2"
    Role = "worker"
  })
}

## Ingress Node (Public Subnet)
resource "aws_instance" "ingress" {
  ami                  = data.aws_ami.ubuntu_24_lts.id
  instance_type        = "t3.medium"
  key_name             = data.aws_key_pair.ansible.key_name
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    # SSM Agent 설치 및 시작
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  primary_network_interface {
    network_interface_id = aws_network_interface.ingress.id
  }

  tags = merge(local.tags, {
    Name = "k8s-ingress-1"
    Role = "ingress"
  })
}

# Ingress 노드용 고정 퍼블릭 IP (EIP) 할당
resource "aws_eip" "ingress" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.ingress.id
  associate_with_private_ip = "10.233.10.15"

  tags = merge(local.tags, {
    Name = "ingress-eip"
  })
}