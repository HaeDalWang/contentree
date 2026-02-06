# POC: Kubernetes 1.29 → 1.31 업그레이드 검증용 최소 인프라
# 베이스: terraform/ (contentree)
terraform {
  required_version = ">= 1.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.26.0"
    }
  }

  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "seungdobae-terraform-state"
    key            = "contentree/terraform-contentree-1.29.tfstate"
    dynamodb_table = "seungdobae-terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-northeast-2"

  default_tags {
    tags = local.tags
  }
}
