# terraform-contentree-1.29

Kubernetes **1.29 → 1.31 업그레이드 POC**용 최소 인프라.  
기존 `terraform/`(contentree) 코드를 베이스로 하며, 분석한 **k8s/kubespray** 및 **k8s/helm**(helmfile) 구성을 사용한다.

## 목적

- **버전 업그레이드 검증**: 최소 노드로 1.29 설치 후 1.31 업그레이드 POC를 직접 진행
- **노드 구성**: 1 Control Plane, 1 Worker, 1 Ingress(Router), 1 Ansible 컨트롤러 (HAProxy/스토리지/인프라 노드 없음)

## 사전 요건

- AWS 계정, S3 백엔드 버킷/ DynamoDB 락 테이블 (기존 `terraform/`와 동일)
- 변수: `domain_name` (예: `joins.net`)

## 사용 방법

### 1. Terraform 적용

```bash
cd terraform-contentree-1.29
terraform init
terraform plan -var="domain_name=joins.net"
terraform apply -var="domain_name=joins.net"
```

### 2. Kubespray 인벤토리 확인

- 인벤토리 YAML 생성:  
  `terraform output -raw kubespray_inventory`
- 저장 경로 권장: **k8s/kubespray/inventory/poc-contentree-1.29/inventory.yaml**  
  (이미 동일 구조의 샘플이 있으므로, Terraform 출력으로 덮어쓰거나 IP만 맞추면 됨)

### 3. Kubespray로 1.29 클러스터 설치

- **인벤토리/변수**: **k8s/kubespray/inventory/** (분석한 고객 구성). POC용 디렉터리 `poc-contentree-1.29` 사용.
- **실행**: Kubespray 프로젝트(cluster.yml 포함)에서 실행. 인벤토리 경로만 `k8s/kubespray/inventory/poc-contentree-1.29` 로 지정.

예시 (실행 위치: Kubespray 클론 루트):

```bash
# 인벤토리는 이 저장소의 k8s/kubespray 쪽 사용
ansible-playbook -i /path/to/contentree/k8s/kubespray/inventory/poc-contentree-1.29/inventory.yaml \
  -e @/path/to/contentree/k8s/kubespray/inventory/variables.yaml \
  -e @/path/to/contentree/k8s/kubespray/inventory/poc-contentree-1.29/variables_poc.yaml \
  cluster.yml
```

- `variables_poc.yaml`: **kube_version: v1.29.18**, 단일 CP용 **apiserver_loadbalancer_domain_name: 10.234.100.10**.
- k8s/kubespray에는 cluster.yml이 없으므로, 공식 Kubespray 클론과 인벤토리 경로만 연동해 실행.

### 4. Helmfile (선택)

- 클러스터 확립 후 **k8s/helm** 의 helmfile으로 최소 배포만 진행해도 됨 (ingress-nginx, metrics-server 등).
- 분석된 **k8s/helm/helmfile.yaml** 사용.

### 5. 업그레이드 POC (1.29 → 1.31)

- Kubespray 공식 upgrade 절차에 따라 1.31로 업그레이드 진행.
- 문서: **docs/upgrade-guide.md** 등 참고.

## 리소스 요약

| 구분 | 개수 | 용도 |
|------|------|------|
| VPC | 1 | 10.234.0.0/16, public 10.234.10.0/24, private 10.234.100.0/24 |
| Ansible | 1 | t3.small, public |
| Control Plane | 1 | t3.medium, 10.234.100.10 |
| Worker | 1 | t3.medium, 10.234.100.20 |
| Ingress | 1 | t3.medium, 10.234.10.15 + EIP |

## Outputs

| Output | 설명 |
|--------|------|
| `control_plane_private_ip` | kubeconfig server 주소 (10.234.100.10) |
| `ansible_controller_public_ip` | Bastion 접속 IP |
| `kubespray_inventory` | 인벤토리 YAML (파일로 저장 후 사용) |
| `ingress_public_ip` | Ingress 노드 EIP |

## 백엔드

- S3 키: `contentree/terraform-contentree-1.29.tfstate`  
- 기존 `terraform/`(contentree)와 상태 분리.
