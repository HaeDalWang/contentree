# cert-manager 네임스페이스
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

# cert-manager Helm 릴리즈
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.17.1"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name

  values = [
    <<-EOT
    crds:
      enabled: true
      keep: true
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.cert_manager_irsa.iam_role_arn}
    resources:
      requests:
        cpu: 10m
        memory: 32Mi
    webhook:
      resources:
        requests:
          cpu: 10m
          memory: 32Mi
    cainjector:
      resources:
        requests:
          cpu: 10m
          memory: 32Mi
    # System 노드에 배포
    nodeSelector:
      workload: system
      nodegroup: system
    tolerations:
      - key: workload
        operator: Equal
        value: system
        effect: NoSchedule
    webhook:
      nodeSelector:
        workload: system
        nodegroup: system
      tolerations:
        - key: workload
          operator: Equal
          value: system
          effect: NoSchedule
    cainjector:
      nodeSelector:
        workload: system
        nodegroup: system
      tolerations:
        - key: workload
          operator: Equal
          value: system
          effect: NoSchedule
    EOT
  ]

  depends_on = [
    module.cert_manager_irsa
  ]
}

# Let's Encrypt ClusterIssuer (Production)
resource "kubectl_manifest" "letsencrypt_issuer" {
  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: ${var.letsencrypt_email}
        privateKeySecretRef:
          name: letsencrypt-prod-key
        solvers:
          - dns01:
              route53:
                region: ${var.aws_region}
            selector:
              dnsZones:
                - "${var.domain_name}"
    YAML

  depends_on = [
    helm_release.cert_manager
  ]
}

# 와일드카드 인증서 (*.joins.seungdobae.com)
resource "kubectl_manifest" "wildcard_certificate" {
  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: wildcard-${local.project_prefix}-${replace(var.domain_name, ".", "-")}
      namespace: envoy-gateway-system
    spec:
      secretName: tls-joins-letsencrypt
      issuerRef:
        name: letsencrypt-prod
        kind: ClusterIssuer
      commonName: "${local.project_domain_name}"
      dnsNames:
        - "${local.project_domain_name}"
        - "*.${local.project_domain_name}"
    YAML

  depends_on = [
    kubectl_manifest.letsencrypt_issuer
  ]
}

