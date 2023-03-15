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

## 수정해야함 Squid 쪽으로 ㄱㄷ
resource "aws_security_group_rule" "kubernetes_egress" {
  security_group_id = aws_security_group.kubernetes.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
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
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.kubernetes.id]
  key_name               = data.aws_key_pair.ansible.key_name

  tags = {
    Name = "master-1"
  }
}
resource "aws_instance" "master2" {

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.small"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.kubernetes.id]
  key_name               = data.aws_key_pair.ansible.key_name

  tags = {
    Name = "master-2"
  }
}

## Haproxy
resource "aws_instance" "haproxy" {

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.small"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.kubernetes.id]
  key_name               = data.aws_key_pair.ansible.key_name

  tags = {
    Name = "haproxy"
  }
}

## Squid proxy
resource "aws_instance" "Squidproxy" {

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.small"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.kubernetes.id]
  key_name               = data.aws_key_pair.ansible.key_name

  tags = {
    Name = "squid-proxy"
  }
}

## ingress
resource "aws_instance" "Squidproxy" {

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.small"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.kubernetes.id]
  key_name               = data.aws_key_pair.ansible.key_name

  tags = {
    Name = "ingress-node"
  }
}

## 3 worker instance
resource "aws_instance" "worker1" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.medium"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.kubernetes.id]
  key_name               = data.aws_key_pair.ansible.key_name

  tags = {
    Name = "worker-1"
  }
}
resource "aws_instance" "worker2" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.medium"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.kubernetes.id]
  key_name               = data.aws_key_pair.ansible.key_name

  tags = {
    Name = "worker-2"
  }
}
resource "aws_instance" "worker3" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.medium"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.kubernetes.id]
  key_name               = data.aws_key_pair.ansible.key_name

  tags = {
    Name = "worker-3"
  }
}
## Jenkins & Harbor
resource "aws_instance" "ci" {

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.medium"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.kubernetes.id]
  key_name               = data.aws_key_pair.ansible.key_name

  tags = {
    Name = "jenkins&Harbor"
  }
}