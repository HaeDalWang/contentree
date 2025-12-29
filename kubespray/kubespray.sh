#!/bin/bash

# 실행 경로 설정
KUBESPRAY_DIR=$(pwd)
INVENTORY_DIR="${KUBESPRAY_DIR}/inventory"
IMAGE="quay.io/kubespray/kubespray:v2.26.0"

# 필요한 디렉토리 생성
mkdir -p "${KUBESPRAY_DIR}/artifacts"

# SSH 키 확인 (ansible-controller의 기본 경로 사용)
SSH_KEY="/home/ubuntu/.ssh/id_rsa"
if [ ! -f "$SSH_KEY" ]; then
    echo "Error: SSH key not found at $SSH_KEY"
    exit 1
fi

echo "Kubespray 컨테이너를 백그라운드에서 실행합니다..."

docker run --name kubespray \
  --hostname SALT-K8S \
  --network host \
  --detach \
  --restart always \
  --mount type=bind,source="${INVENTORY_DIR}",dst=/kubespray/inventory \
  --mount type=bind,source="${KUBESPRAY_DIR}/extra_playbooks",dst=/kubespray/extra_playbooks \
  --mount type=bind,source="${KUBESPRAY_DIR}/artifacts",dst=/kubespray/artifacts \
  --mount type=bind,source="${SSH_KEY}",dst=/root/.ssh/id_rsa,readonly \
  --env ANSIBLE_HOST_KEY_CHECKING=False \
  "$IMAGE" \
  sleep infinity

echo "--------------------------------------------------"
echo "컨테이너 실행 완료: kubespray"
echo "컨테이너 접속: docker exec -it kubespray bash"
echo "클러스터 배포: bash /kubespray/inventory/run.sh"
echo "--------------------------------------------------"
