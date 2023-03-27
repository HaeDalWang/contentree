## Amazon linux2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  owners = ["amazon"]
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
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.small"
  subnet_id     = module.vpc.public_subnets[0]
  key_name      = data.aws_key_pair.ansible.key_name

  tags = {
    Name = "ansible-controller"
  }
}

#---------------------------------------------------------------
#  인스턴스 생성 
# pri: master2, ha1 ,worker3(app,infra,storage), jenkins,Harbor1
# pub: squidproxy1, ingressnode1
#---------------------------------------------------------------

## 2 master instance
resource "aws_instance" "master1" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.small"
  key_name               = data.aws_key_pair.ansible.key_name
  network_interface {
    network_interface_id = aws_network_interface.master1.id
    device_index = 0
  }
  tags = {
    Name = "master-1"
  }
}
# resource "aws_instance" "master2" {
#   ami                    = data.aws_ami.amazon_linux_2.id
#   instance_type          = "t3.small"
#   key_name               = data.aws_key_pair.ansible.key_name
#   network_interface {
#     network_interface_id = aws_network_interface.master2.id
#     device_index = 0
#   }
#   tags = {
#     Name = "master-2"
#   }
# }

## Haproxy
resource "aws_instance" "haproxy" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.small"
  key_name               = data.aws_key_pair.ansible.key_name
  network_interface {
    network_interface_id = aws_network_interface.ha1.id
    device_index = 0
  }
  tags = {
    Name = "haproxy"
  }
}

## Squid proxy
resource "aws_instance" "Squidproxy" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.small"
  key_name               = data.aws_key_pair.ansible.key_name
  network_interface {
    network_interface_id = aws_network_interface.squid.id
    device_index = 0
  }
  tags = {
    Name = "squid-proxy"
  }
}

## ingress
resource "aws_instance" "ingress" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.medium"
  key_name               = data.aws_key_pair.ansible.key_name
  network_interface {
    network_interface_id = aws_network_interface.ingress.id
    device_index = 0
  }
  tags = {
    Name = "ingress-node"
  }
}

## 3 worker instance
resource "aws_instance" "worker1" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.medium"
  key_name               = data.aws_key_pair.ansible.key_name
  network_interface {
    network_interface_id = aws_network_interface.worker1.id
    device_index = 0
  }
  tags = {
    Name = "worker-1"
  }
}
resource "aws_instance" "worker2" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.medium"
  key_name               = data.aws_key_pair.ansible.key_name
  network_interface {
    network_interface_id = aws_network_interface.worker2.id
    device_index = 0
  }
  tags = {
    Name = "worker-2"
  }
}
resource "aws_instance" "worker3" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.medium"
  key_name               = data.aws_key_pair.ansible.key_name
  network_interface {
    network_interface_id = aws_network_interface.worker3.id
    device_index = 0
  }
  tags = {
    Name = "worker-3"
  }
}
## Jenkins & Harbor
resource "aws_instance" "ci" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.medium"
  key_name               = data.aws_key_pair.ansible.key_name
  network_interface {
    network_interface_id = aws_network_interface.ci.id
    device_index = 0
  }
  tags = {
    Name = "jenkins&Harbor"
  }
}