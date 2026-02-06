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

data "aws_key_pair" "ansible" {
  key_name = var.ssh_key_name
}

#---------------------------------------------------------------
# Ansible 컨트롤러 (Kubespray 실행용)
#---------------------------------------------------------------
resource "aws_instance" "ansible_controller" {
  ami                         = data.aws_ami.ubuntu_24_lts.id
  instance_type               = "t3.small"
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = data.aws_key_pair.ansible.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  vpc_security_group_ids      = [aws_security_group.kubernetes.id]

  user_data = <<-EOF
    #!/bin/bash
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  tags = merge(local.tags, {
    Name = "${local.project}-ansible"
    Role = "ansible-controller"
  })
}

#---------------------------------------------------------------
# Control Plane 3대 — 인벤토리 호스트명: mvd-kubecp01~03
#---------------------------------------------------------------
resource "aws_instance" "mvd_kubecp01" {
  ami                  = data.aws_ami.ubuntu_24_lts.id
  instance_type        = "t3.medium"
  key_name             = data.aws_key_pair.ansible.key_name
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  primary_network_interface {
    network_interface_id = aws_network_interface.mvd_kubecp01.id
  }

  tags = merge(local.tags, {
    Name = "mvd-kubecp01"
    Role = "master"
  })
}

resource "aws_instance" "mvd_kubecp02" {
  ami                  = data.aws_ami.ubuntu_24_lts.id
  instance_type        = "t3.medium"
  key_name             = data.aws_key_pair.ansible.key_name
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  primary_network_interface {
    network_interface_id = aws_network_interface.mvd_kubecp02.id
  }

  tags = merge(local.tags, {
    Name = "mvd-kubecp02"
    Role = "master"
  })
}

resource "aws_instance" "mvd_kubecp03" {
  ami                  = data.aws_ami.ubuntu_24_lts.id
  instance_type        = "t3.medium"
  key_name             = data.aws_key_pair.ansible.key_name
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  primary_network_interface {
    network_interface_id = aws_network_interface.mvd_kubecp03.id
  }

  tags = merge(local.tags, {
    Name = "mvd-kubecp03"
    Role = "master"
  })
}

#---------------------------------------------------------------
# Worker 3대 — 인벤토리 호스트명: mvd-kubewk01~03
#---------------------------------------------------------------
resource "aws_instance" "mvd_kubewk01" {
  ami                  = data.aws_ami.ubuntu_24_lts.id
  instance_type        = "t3.medium"
  key_name             = data.aws_key_pair.ansible.key_name
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  primary_network_interface {
    network_interface_id = aws_network_interface.mvd_kubewk01.id
  }

  tags = merge(local.tags, {
    Name = "mvd-kubewk01"
    Role = "worker"
  })
}

resource "aws_instance" "mvd_kubewk02" {
  ami                  = data.aws_ami.ubuntu_24_lts.id
  instance_type        = "t3.medium"
  key_name             = data.aws_key_pair.ansible.key_name
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  primary_network_interface {
    network_interface_id = aws_network_interface.mvd_kubewk02.id
  }

  tags = merge(local.tags, {
    Name = "mvd-kubewk02"
    Role = "worker"
  })
}

resource "aws_instance" "mvd_kubewk03" {
  ami                  = data.aws_ami.ubuntu_24_lts.id
  instance_type        = "t3.medium"
  key_name             = data.aws_key_pair.ansible.key_name
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  primary_network_interface {
    network_interface_id = aws_network_interface.mvd_kubewk03.id
  }

  tags = merge(local.tags, {
    Name = "mvd-kubewk03"
    Role = "worker"
  })
}

#---------------------------------------------------------------
# Ingress(Router) 1대 — 인벤토리 호스트명: mvd-kubert01
#---------------------------------------------------------------
resource "aws_instance" "mvd_kubert01" {
  ami                  = data.aws_ami.ubuntu_24_lts.id
  instance_type        = "t3.medium"
  key_name             = data.aws_key_pair.ansible.key_name
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  primary_network_interface {
    network_interface_id = aws_network_interface.mvd_kubert01.id
  }

  tags = merge(local.tags, {
    Name = "mvd-kubert01"
    Role = "ingress"
  })
}

resource "aws_eip" "ingress" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.mvd_kubert01.id
  associate_with_private_ip = "10.150.44.16"

  tags = merge(local.tags, { Name = "${local.project}-ingress-eip" })
}
