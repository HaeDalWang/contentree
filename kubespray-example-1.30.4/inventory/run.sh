#!/bin/bash

# Kubespray 배포 실행 스크립트 (컨테이너 내부용)

# kubespray 루트 디렉토리로 이동
cd /kubespray

echo "=========================================="
echo "1단계: 노드 연결 테스트 (ping)"
echo "=========================================="
ansible all -i inventory/inventory.yaml -m ping

if [ $? -ne 0 ]; then
  echo "❌ 노드 연결 실패! 연결을 확인한 후 다시 시도하세요."
  exit 1
fi

echo ""
echo "✅ 모든 노드 연결 성공!"
echo ""
echo "=========================================="
echo "2단계: Kubernetes 클러스터 배포 시작"
echo "=========================================="

ansible-playbook -i inventory/inventory.yaml \
  --extra-vars "@/inventory/variables.yaml" \
  --become --become-user=root \
  cluster.yml

