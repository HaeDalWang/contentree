variable "domain_name" {
  description = "클러스터 루트 도메인 (기존 contentree와 동일하게 사용 가능)"
  type        = string
}

variable "ssh_key_name" {
  description = "EC2 접속용 키 페어 이름"
  type        = string
  default     = "saltware"
}
