# TLS 인증서 - joins.seungdobae.com
# 자체 서명 인증서 (Self-Signed Certificate)

# 개인 키 생성
resource "tls_private_key" "joins" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 자체 서명 인증서 생성
resource "tls_self_signed_cert" "joins" {
  private_key_pem = tls_private_key.joins.private_key_pem

  subject {
    common_name  = "joins.seungdobae.com"
    organization = "Seungdo Bae"
  }

  # 인증서에 포함할 도메인
  dns_names = [
    "joins.seungdobae.com",
    "*.joins.seungdobae.com"
  ]

  # 유효 기간: 1년
  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Kubernetes TLS Secret 생성
resource "kubernetes_secret" "tls_joins" {
  metadata {
    name      = "tls-joins.net"
    namespace = "envoy-gateway-system"
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.joins.cert_pem
    "tls.key" = tls_private_key.joins.private_key_pem
  }
}

