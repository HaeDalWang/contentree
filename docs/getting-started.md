# Kubespray를 이용한 Kubernetes 클러스터 구축 가이드

## 개요

이 문서는 AWS 환경에서 Terraform과 Kubespray를 사용하여 Kubernetes 클러스터를 구축하는 전체 과정을 설명합니다.

---

## 📋 사전 요구사항

- AWS 계정 및 적절한 IAM 권한
- Terraform 설치 (로컬 PC)
- SSH 키 페어 (예: `~/.ssh/saltware.pem`)

---

## 🏗️ 1단계: 인프라 생성 (Terraform)

로컬 PC에서 Terraform을 실행하여 AWS 리소스를 생성합니다.

```bash
cd terraform
```

```bash
terraform init
```

```bash
terraform apply
```

> 생성되는 리소스: VPC, EC2 (1 Master, 2 Worker, 1 Ingress, 1 Ansible Controller)

---

## 🔐 2단계: Ansible Controller 접속

AWS 콘솔에서 **Session Manager**를 통해 `ansible-controller` 인스턴스에 접속합니다.

### 2-1. ubuntu 사용자 패스워드 설정

```bash
sudo passwd ubuntu
```

원하는 패스워드를 입력합니다.

### 2-2. ubuntu 사용자로 전환

```bash
su ubuntu
```

```bash
cd
```

---

## 📦 3단계: 프로젝트 클론 및 환경 구성

### 3-1. Git 저장소 클론

```bash
git clone https://github.com/HaeDalWang/contentree.git
```

```bash
cd contentree/kubespray/
```

### 3-2. Docker 설치 스크립트 실행

```bash
./init-env.sh
```

### 3-3. Docker 그룹 적용

```bash
newgrp docker
```

### 3-4. Docker 설치 확인

```bash
docker ps
```

> `CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES` 형태의 빈 테이블이 출력되면 정상입니다.

---

## 🔑 4단계: SSH 키 복사

**로컬 PC**에서 Ansible Controller로 SSH 키를 복사합니다.

> 이 키는 Ansible이 모든 노드(Master, Worker, Ingress)에 접속할 때 사용됩니다.

### 로컬 PC 터미널에서 실행:

```bash
scp -i ~/.ssh/saltware.pem ~/.ssh/saltware.pem ubuntu@<ansible-controller-ip>:/home/ubuntu/.ssh/id_rsa
```

> `<ansible-controller-ip>`는 Terraform 출력 또는 AWS 콘솔에서 확인할 수 있습니다.

---

## ⚙️ 5단계: Kubespray 컨테이너 실행

**Ansible Controller**에서 계속 진행합니다.

### 5-1. SSH 키 확인

```bash
ls ~/.ssh
```

> `id_rsa` 파일이 있어야 합니다.

### 5-2. 결과물 저장 디렉토리 생성

```bash
mkdir artifacts
```

### 5-3. Kubespray 컨테이너 실행

```bash
./kubespray.sh
```

### 5-4. Kubespray 컨테이너 접속

```bash
docker exec -it kubespray bash
```

---

## 🚀 6단계: Kubernetes 클러스터 배포

**Kubespray 컨테이너 내부**에서 실행합니다.

### 6-1. 노드 연결 상태 확인

```bash
ansible all -i inventory/inventory.yaml -m ping
```

> 모든 노드에서 `pong` 응답이 와야 합니다. 실패 시 SSH 키 또는 네트워크 설정을 확인하세요.

### 6-2. 클러스터 배포 실행

```bash
ansible-playbook -i inventory/inventory.yaml \
  --extra-vars "@inventory/variables.yaml" \
  --become --become-user=root \
  cluster.yml
```

> ⏱️ 소요 시간: 약 15~30분

---

## ✅ 7단계: 클러스터 확인 (컨테이너 내부)

배포 완료 후, **Kubespray 컨테이너 내부**에서 클러스터 상태를 확인합니다.

### 7-1. kubeconfig 설정

```bash
cd artifacts
```

```bash
mkdir ~/.kube
```

```bash
cp ./admin.conf ~/.kube/config
```

### 7-2. 노드 상태 확인

```bash
kubectl get node
```

예상 출력:

```
NAME            STATUS   ROLES           AGE   VERSION
k8s-ingress-1   Ready    ingress         5m    v1.30.4
k8s-master-1    Ready    control-plane   6m    v1.30.4
k8s-worker-1    Ready    worker          5m    v1.30.4
k8s-worker-2    Ready    worker          5m    v1.30.4
```

### 7-3. 컨테이너 종료

```bash
exit
```

---

## 🖥️ 8단계: Ansible Controller에서 kubectl 설정

**Ansible Controller (EC2)**에서 직접 kubectl을 사용할 수 있도록 설정합니다.

### 8-1. artifacts 디렉토리로 이동

```bash
cd /home/ubuntu/contentree/kubespray/artifacts
```

### 8-2. kubeconfig 디렉토리 생성

```bash
mkdir ~/.kube
```

### 8-3. 파일 권한 설정

```bash
sudo chmod 777 admin.conf
```

```bash
sudo chmod 777 kubectl
```

### 8-4. 파일 복사

```bash
sudo cp admin.conf ~/.kube/config
```

```bash
sudo cp kubectl /usr/local/bin/kubectl
```

### 8-5. kubectl 자동완성 설정

```bash
echo "source <(kubectl completion bash)" >> ~/.bashrc
```

```bash
source ~/.bashrc
```

### 8-6. 클러스터 확인

```bash
kubectl get nodes
```

---

## 🎉 완료

Kubernetes 클러스터가 성공적으로 구축되었습니다!

---

## 📚 참고 문서

- [트러블슈팅 가이드](./troubleshooting/kubespray-version-compatibility.md)
- [Kubespray 공식 문서](https://kubespray.io/)
- [Kubernetes 공식 문서](https://kubernetes.io/docs/)

---

## ⚠️ 주의사항

1. **버전 호환성**: Kubespray 버전과 Kubernetes 버전이 호환되는지 확인하세요.
2. **네트워크 대역**: VPC CIDR과 Kubernetes Service/Pod CIDR이 겹치지 않아야 합니다.
3. **SSH 키**: 모든 노드에 동일한 SSH 키로 접속 가능해야 합니다.
