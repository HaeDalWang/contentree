#!/bin/bash

# Kubespray 배포 실행 스크립트 (컨테이너 내부용)
echo "Kubernetes 클러스터 배포를 시작합니다..."

ansible-playbook -i /kubespray/inventory/inventory.yaml \
  --extra-vars "@/kubespray/inventory/variables.yaml" \
  --become --become-user=root \
  cluster.yml

