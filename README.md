# contentree 환경 테스트

## Terraform으로 VPC,EC2 생성
- 1 master, 2worker, 1 ingress

## Kubespray를 통한 배포 
- kubespray 공식 컨테이너 이미지 사용 

## 문서
- [트러블슈팅 가이드](./docs/troubleshooting/) - Kubespray 배포 시 발생할 수 있는 문제 해결 방법

## 버전 호환성

| Kubespray 버전 | Kubernetes 기본 버전 | 컨테이너 이미지 |
|---------------|---------------------|----------------|
| v2.26.0       | v1.30.4             | `quay.io/kubespray/kubespray:v2.26.0` |

> **주의**: Kubespray 버전별로 지원하는 Kubernetes 버전이 다릅니다. `variables.yaml`에서 `kube_version` 설정 시 반드시 호환되는 버전을 사용하세요.

## 사용 하기

cd terraform
terraform init 
terraform apply

콘솔에서 ansible-controller의 접속 세션매니저

ec2안에서
sudo passwd ubuntu
-> 패스워드 원하는걸로
su ubuntu
cd

git clone https://github.com/HaeDalWang/contentree.git
cd contentree/kubespray/
./init-env.sh
newgrp docker

도커 설치 확인
docker ps

로컬 PC에서 > 앤서블 컨트롤러로 키복사 (해당키로 모든 노드/마스터에 ansible사용 예정)
``` bash
scp -i ~/.ssh/saltware.pem ~/.ssh/saltware.pem ubuntu@<ansible-instance-ip>:/home/ubuntu/.ssh/id_rsa
```

다시 ec2

복사한 id_rsa 키 확인
ls ~/.ssh

결과물 저장할 디텍토리
mkdir artifacts

큐브스프레이 환경 구성
./kubespray.sh

컨테이너 안 진입
docker exec -it kubespray bash

노드 상태 확인 (무조건 pong)이 와야함
ansible all -i inventory/inventory.yaml -m ping

확인되면 클러스터 배포 시작
{
ansible-playbook -i inventory/inventory.yaml \
  --extra-vars "@inventory/variables.yaml" \
  --become --become-user=root \
  cluster.yml
}

설정파일 복사
cd artifacts
mkdir ~/.kube
cp ./admin.conf ~/.kube/config

노드 확인
kubectl get node

exit

cd /home/ubuntu/contentree/kubespray/artifacts
mkdir ~/.kube
sudo chmod 777 admin.conf
sudo chmod 777 kubectl
sudo cp admin.conf ~/.kube/config
sudo cp kubectl /usr/local/bin/kubectl

자동완성
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc




## 재설정 및 재적용
# 클러스터 리셋
{
ansible-playbook -i inventory/inventory.yaml \
  --extra-vars "@inventory/variables.yaml" \
  --become --become-user=root \
  reset.yml
}
