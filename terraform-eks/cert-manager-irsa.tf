# cert-manager용 IRSA (IAM Roles for Service Accounts)
# Route53 DNS-01 챌린지를 위한 권한

# IAM Policy - Route53 접근 권한
resource "aws_iam_policy" "cert_manager" {
  name        = "${local.project}-cert-manager"
  description = "Policy for cert-manager to manage Route53 records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:GetChange"
        ]
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        # 특정 호스팅 존만 허용하려면 아래처럼 수정
        # Resource = "arn:aws:route53:::hostedzone/YOUR_HOSTED_ZONE_ID"
        Resource = "arn:aws:route53:::hostedzone/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZonesByName",
          "route53:ListHostedZones"
        ]
        Resource = "*"
      }
    ]
  })
}

# IRSA Role
module "cert_manager_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${local.project}-cert-manager"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
    }
  }
}

# Policy 연결
resource "aws_iam_role_policy_attachment" "cert_manager" {
  role       = module.cert_manager_irsa.iam_role_name
  policy_arn = aws_iam_policy.cert_manager.arn
}

# 출력 - helm values에 넣을 값
output "cert_manager_role_arn" {
  description = "cert-manager IRSA Role ARN"
  value       = module.cert_manager_irsa.iam_role_arn
}

