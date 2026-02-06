#!/bin/bash

# Ubuntu 24.04에서 Docker 설치 스크립트

set -e

echo "Docker 설치를 시작합니다..."

# 기존 Docker 제거 (선택사항)
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# 필수 패키지 설치
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Docker 공식 GPG 키 추가
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Docker 저장소 추가
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker 설치
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker 서비스 시작 및 자동 시작 설정
sudo systemctl enable docker
sudo systemctl start docker

# 현재 사용자를 docker 그룹에 추가 (sudo 없이 docker 사용 가능)
sudo usermod -aG docker $USER

# Docker 버전 확인
echo "Docker 설치 완료!"
docker --version
docker compose version

#---------------------------------------------------------------
# Helm 설치
#---------------------------------------------------------------
HELM_VERSION="${HELM_VERSION:-v3.16.4}"
echo ""
echo "Helm ${HELM_VERSION} 설치 중..."
curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" | tar xz
sudo mv linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64
echo "Helm 설치 완료: $(helm version --short)"

#---------------------------------------------------------------
# Helmfile 설치
#---------------------------------------------------------------
HELMFILE_VERSION="${HELMFILE_VERSION:-v0.169.2}"
HELMFILE_ARCH="helmfile_${HELMFILE_VERSION#v}_linux_amd64.tar.gz"
echo ""
echo "Helmfile ${HELMFILE_VERSION} 설치 중..."
curl -fsSL "https://github.com/helmfile/helmfile/releases/download/${HELMFILE_VERSION}/${HELMFILE_ARCH}" | tar xz
sudo mv helmfile /usr/local/bin/helmfile
echo "Helmfile 설치 완료: $(helmfile --version)"

echo ""
echo "주의: docker 그룹 적용을 위해 로그아웃 후 다시 로그인하거나 다음 명령어를 실행하세요:"
echo "  newgrp docker"

