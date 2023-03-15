#---------------------------------------------------------------
# 프로바이더 및 로컬 변수 지정
#---------------------------------------------------------------

provider "aws" {
  region = local.region
}

locals {
  name        = "kubespray-infra"
  environment = "test"
  region      = "ap-northeast-2"
  tags = {
    environment = "test"
  }
}