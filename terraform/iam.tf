# EC2 서비스용 IAM Role
resource "aws_iam_role" "ssm_role" {
  name = "${local.project}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

# SSM 접속을 위한 Managed Policy 연결 (AmazonSSMManagedInstanceCore)
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 인스턴스에 적용할 Instance Profile
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${local.project}-ssm-profile"
  role = aws_iam_role.ssm_role.name

  tags = local.tags
}

