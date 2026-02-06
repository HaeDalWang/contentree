locals {
  project        = "contentree-1.29"
  project_prefix = "joins"
  domain_name    = var.domain_name
  project_domain_name = "${local.project_prefix}.${local.domain_name}"

  tags = {
    "terraform" = "true"
    "project"   = local.project
    "purpose"   = "k8s-upgrade-poc"
  }
}
