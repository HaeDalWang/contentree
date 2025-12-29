# 요구되는 테라폼 제공자 목록
# 버전 기준: 2025년 10월 23일
terraform {
  required_version = ">= 1.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.26.0"
    }
  }
}

# 테라폼 백엔드 설정
terraform {
  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "seungdobae-terraform-state"
    key            = "contentree/terraform.tfstate"
    dynamodb_table = "seungdobae-terraform-lock"
    encrypt        = true
  }
}

# AWS 제공자 설정
provider "aws" {
  region = "ap-northeast-2" # 서울 리전
  
  # 해당 테라폼 모듈을 통해서 생성되는 모든 AWS 리소스에 아래의 태그 부여
  default_tags {
    tags = local.tags
  }
}