# Kubespray를 이용한 Kubernetes 클러스터 업그레이드 가이드

## 개요

이 문서는 Kubespray로 배포된 Kubernetes 클러스터를 안전하게 업그레이드하는 전체 과정을 설명합니다.

> **중요**: 업그레이드는 신중하게 진행해야 합니다. 반드시 사전 확인 및 백업을 완료한 후 진행하세요.

---

## 📋 사전 요구사항

- 정상 동작 중인 Kubernetes 클러스터
- Kubespray 컨테이너 접속 가능
- 클러스터 관리자 권한 (kubectl 접근 가능)

---

## 🔍 1단계: 현재 상태 확인

업그레이드 전 반드시 현재 클러스터 상태를 확인합니다.

### 1-1. 현재 Kubernetes 버전 확인

```bash
kubectl version
```

### 1-2. 노드 상태 확인

```bash
kubectl get nodes
```

> 모든 노드가 `Ready` 상태여야 합니다. `NotReady` 노드가 있으면 먼저 해결하세요.

### 1-3. 파드 상태 확인

```bash
kubectl get pod -A
```

> 모든 시스템 파드가 `Running` 상태여야 합니다.

### 1-4. 현재 Kubespray 버전 확인

Kubespray 컨테이너 내부에서:

```bash
cat /kubespray/galaxy.yml | grep version
```

---

## 📚 2단계: 버전 호환성 확인 (매우 중요!)

### 2-1. Kubespray 릴리스 페이지 확인

**반드시 확인해야 할 링크:**

👉 [Kubespray GitHub Releases](https://github.com/kubernetes-sigs/kubespray/releases)

이 페이지에서 확인할 내용:

1. **현재 사용 중인 Kubespray 버전이 지원하는 Kubernetes 버전 범위**
2. **업그레이드하려는 Kubernetes 버전이 지원되는지**

예시 (Kubespray v2.26.0):
```
Supported Kubernetes versions:
- v1.29.x 안됨
- v1.30.x (기본값: v1.30.4)
- v1.31.x 됨
```

### 2-2. Kubernetes 버전 업그레이드 규칙

| 규칙 | 설명 | 예시 |
|-----|------|-----|
| **마이너 버전 순차 업그레이드** | 한 번에 하나의 마이너 버전만 업그레이드 가능 | 1.29 → 1.30 → 1.31 (O) |
| **마이너 버전 건너뛰기 금지** | 중간 버전을 건너뛸 수 없음 | 1.29 → 1.31 (X) |
| **패치 버전은 자유** | 같은 마이너 버전 내에서는 자유롭게 이동 가능 | 1.30.0 → 1.30.4 (O) |

### 2-3. Kubespray 변수 문서 확인

**반드시 확인해야 할 링크:**

👉 [Kubespray Variables Documentation](https://kubespray.io/#/docs/ansible/vars)

이 페이지에서 확인할 내용:

1. **새 버전에서 변경된 변수**
2. **deprecated된 변수**
3. **새로 추가된 필수 변수**

### 2-4. Kubernetes Changelog 확인 (선택)

**참고 링크:**

👉 [Kubernetes CHANGELOG](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.31.md)

이 페이지에서 확인할 내용:

1. **Breaking Changes** - 기존 기능 변경/제거
2. **Deprecations** - 향후 제거될 기능
3. **API Changes** - API 버전 변경

---

## 🔬 3단계: Deprecated API 호환성 검사 (kubent)

### kubent란?

**kubent (Kube-No-Trouble)**는 클러스터에서 **deprecated API**를 사용하는 리소스를 자동으로 찾아주는 도구입니다.

Kubernetes 버전이 올라가면 일부 API가 제거되거나 변경됩니다. 업그레이드 전에 이 도구로 검사하면 **업그레이드 후 장애를 예방**할 수 있습니다.

👉 [kubent GitHub Repository](https://github.com/doitintl/kube-no-trouble)

**왜 사용하는가?**

| 상황 | 문제 |
|-----|------|
| `apps/v1beta1` Deployment 사용 중 | 1.16+ 에서 API 제거됨 → 워크로드 실패 |
| `extensions/v1beta1` Ingress 사용 중 | 1.22+ 에서 API 제거됨 → Ingress 동작 안함 |
| `policy/v1beta1` PodSecurityPolicy 사용 중 | 1.25+ 에서 완전 제거됨 |

### 3-1. kubent 설치

**Ansible Controller (EC2)**에서 실행:

```bash
sh -c "$(curl -sSL https://git.io/install-kubent)"
```

> `/usr/local/bin/kubent`에 설치됩니다.

설치 확인:

```bash
kubent --version
```

### 3-2. Deprecated API 검사 실행

```bash
kubent
```

**정상 출력 예시 (문제 없음):**

```
4:25PM INF >>> Kube No Trouble `kubent` <<<
4:25PM INF Initializing collectors and retrieving data
4:25PM INF Retrieved 45 resources from collector name=Cluster
4:25PM INF Retrieved 0 resources from collector name="Helm v3"
4:25PM INF Loaded ruleset name=deprecated-1-16.rego
4:25PM INF Loaded ruleset name=deprecated-1-22.rego
4:25PM INF Loaded ruleset name=deprecated-1-25.rego
4:25PM INF Loaded ruleset name=deprecated-1-26.rego
4:25PM INF Loaded ruleset name=deprecated-1-27.rego
4:25PM INF Loaded ruleset name=deprecated-1-29.rego
4:25PM INF Loaded ruleset name=deprecated-1-32.rego
```

> 아무런 테이블이 출력되지 않으면 deprecated API를 사용하는 리소스가 없는 것입니다. ✅

**문제 발견 시 출력 예시:**

```
__________________________________________________________________________________________
>>> 1.22 Deprecated APIs <<<
------------------------------------------------------------------------------------------
KIND      NAMESPACE   NAME           API_VERSION
Ingress   default     my-ingress     extensions/v1beta1
Ingress   app         web-ingress    networking.k8s.io/v1beta1
__________________________________________________________________________________________
>>> 1.25 Deprecated APIs <<<
------------------------------------------------------------------------------------------
KIND                  NAMESPACE   NAME              API_VERSION
PodSecurityPolicy     <none>      restricted-psp    policy/v1beta1
```

### 3-3. 특정 버전 대상 검사

업그레이드 대상 버전을 지정하여 검사:

```bash
kubent -t 1.31
```

> `-t` 옵션으로 **target version**을 지정하면 해당 버전에서 문제가 될 API만 표시합니다.

### 3-4. JSON 형식 출력 (CI/자동화용)

```bash
kubent -o json
```

### 3-5. 문제 발견 시 조치

| deprecated API | 대체 API | 조치 방법 |
|---------------|---------|----------|
| `extensions/v1beta1` Ingress | `networking.k8s.io/v1` | manifest 수정 후 재배포 |
| `apps/v1beta1` Deployment | `apps/v1` | manifest 수정 후 재배포 |
| `policy/v1beta1` PodSecurityPolicy | Pod Security Admission | PSA로 마이그레이션 |

**manifest 수정 예시:**

```yaml
# 변경 전 (deprecated)
apiVersion: extensions/v1beta1
kind: Ingress

# 변경 후
apiVersion: networking.k8s.io/v1
kind: Ingress
```

> **중요**: kubent에서 문제가 발견되면 **반드시 수정 후** 업그레이드를 진행하세요!

### 3-6. Helm 차트 검사

Helm으로 배포된 리소스도 함께 검사합니다:

```bash
kubent --helm3
```

> Helm release의 Secret/ConfigMap에서 manifest를 읽어 검사합니다.

### 3-7. 로컬 manifest 파일 검사

배포 전 YAML 파일 검사:

```bash
kubent -f deployment.yaml -f ingress.yaml
```

디렉토리 전체 검사:

```bash
kubent -f ./manifests/
```

---

## ⚙️ 4단계: 업그레이드 준비

### 3-1. Kubespray 컨테이너 접속

```bash
docker exec -it kubespray bash
```

### 3-2. variables.yaml 수정

```bash
vi /kubespray/inventory/variables.yaml
```

버전 관련 설정 변경:

```yaml
# 업그레이드할 Kubernetes 버전 지정
kube_version: v1.31.0

# 필요 시 컴포넌트 버전도 함께 조정
# calico_version: v3.28.2
# containerd_version: 1.7.22
```

> **주의**: Kubespray가 지원하는 버전만 사용하세요. 지원하지 않는 버전 사용 시 checksum 에러가 발생합니다.

### 3-3. 변경 내용 확인

```bash
cat /kubespray/inventory/variables.yaml | grep kube_version
```

---

## 🔄 5단계: 업그레이드 실행

### 업그레이드 방식 선택

| 방식 | 장점 | 단점 | 권장 환경 |
|-----|------|------|----------|
| **전체 업그레이드** | 간단함, 빠름 | 롤백 어려움 | 개발/테스트 |
| **순차 업그레이드** | 안전함, 서비스 영향 최소화 | 시간 소요 | **프로덕션** |

---

### 방식 A: 전체 업그레이드 (개발/테스트 환경)

모든 노드를 한 번에 업그레이드합니다.

```bash
ansible-playbook -i inventory/inventory.yaml \
  --extra-vars "@inventory/variables.yaml" \
  --become --become-user=root \
  upgrade-cluster.yml
```

---

### 방식 B: 순차 업그레이드 (프로덕션 권장)

Control Plane과 Worker Node를 분리하여 순차적으로 업그레이드합니다.

#### B-1. Control Plane 업그레이드

**왜 먼저 하는가?**
- Kubernetes는 Control Plane이 Worker보다 **같거나 높은 버전**이어야 함
- API Server, Controller Manager, Scheduler가 새 버전 기능을 먼저 지원해야 Worker가 사용 가능

```bash
ansible-playbook -i inventory/inventory.yaml \
  --extra-vars "@inventory/variables.yaml" \
  --become --become-user=root \
  --limit "kube_control_plane" \
  upgrade-cluster.yml
```

#### B-2. Control Plane 업그레이드 확인

```bash
kubectl get nodes
```

예상 출력:
```
NAME            STATUS   ROLES           VERSION
k8s-master-1    Ready    control-plane   v1.31.0   ← 업그레이드됨
k8s-worker-1    Ready    worker          v1.30.4   ← 아직 이전 버전
k8s-worker-2    Ready    worker          v1.30.4
k8s-ingress-1   Ready    ingress         v1.30.4
```

> Control Plane만 새 버전으로 업그레이드된 것을 확인합니다.

#### B-3. Worker Node 업그레이드

**왜 분리하는가?**
- 워크로드가 실행 중인 노드를 순차적으로 업그레이드하여 서비스 중단 최소화
- 문제 발생 시 일부 노드만 롤백 가능

```bash
ansible-playbook -i inventory/inventory.yaml \
  --extra-vars "@inventory/variables.yaml" \
  --become --become-user=root \
  --limit "kube_node:!kube_control_plane" \
  upgrade-cluster.yml
```

> `kube_node:!kube_control_plane` = kube_node 그룹에서 control_plane 제외 (순수 Worker만)

#### B-4. 전체 업그레이드 확인

```bash
kubectl get nodes
```

예상 출력:
```
NAME            STATUS   ROLES           VERSION
k8s-master-1    Ready    control-plane   v1.31.0   ← 업그레이드됨
k8s-worker-1    Ready    worker          v1.31.0   ← 업그레이드됨
k8s-worker-2    Ready    worker          v1.31.0   ← 업그레이드됨
k8s-ingress-1   Ready    ingress         v1.31.0   ← 업그레이드됨
```

---

### 방식 C: 노드별 개별 업그레이드 (고가용성 환경)

특정 노드만 선택하여 업그레이드합니다.

```bash
# 특정 Worker 노드만 업그레이드
ansible-playbook -i inventory/inventory.yaml \
  --extra-vars "@inventory/variables.yaml" \
  --become --become-user=root \
  --limit "k8s-worker-1" \
  upgrade-cluster.yml
```

---

## ✅ 6단계: 업그레이드 검증

### 5-1. 노드 버전 확인

```bash
kubectl get nodes -o wide
```

### 5-2. 시스템 파드 상태 확인

```bash
kubectl get pod -n kube-system
```

> 모든 파드가 `Running` 상태여야 합니다.

### 5-3. 클러스터 컴포넌트 버전 확인

```bash
kubectl version
```

### 5-4. 테스트 파드 배포

```bash
kubectl run test-nginx --image=nginx:latest
```

```bash
kubectl get pod test-nginx
```

```bash
kubectl delete pod test-nginx
```

### 5-5. DNS 확인

```bash
kubectl run test-dns --image=busybox:1.28 --rm -it --restart=Never -- nslookup kubernetes
```

---

## 🚨 트러블슈팅

### 에러 1: Checksum 에러

```
FAILED! => checksum mismatch
```

**원인**: Kubespray가 지원하지 않는 Kubernetes 버전 사용

**해결**: Kubespray 릴리스 페이지에서 지원 버전 확인 후 수정

### 에러 2: 노드 NotReady

```
k8s-worker-1   NotReady   worker   v1.31.0
```

**해결**:
```bash
# 해당 노드에서 kubelet 상태 확인
ssh ubuntu@<node-ip>
sudo systemctl status kubelet
sudo journalctl -u kubelet -n 100
```

### 에러 3: 파드 Pending/CrashLoop

**해결**:
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

---

## 📌 주의사항 요약

1. **버전 호환성 확인 필수** - Kubespray 릴리스 페이지 확인
2. **kubent로 Deprecated API 검사** - 업그레이드 전 반드시 실행
3. **마이너 버전 순차 업그레이드** - 1.29 → 1.30 → 1.31 순서로
4. **프로덕션은 순차 업그레이드** - Control Plane → Worker 순서
5. **업그레이드 전 백업** - etcd 스냅샷, 중요 리소스 YAML 백업
6. **테스트 환경 먼저** - 프로덕션 전 테스트 클러스터에서 검증

---

## 📚 참고 링크

| 문서 | 링크 | 확인 내용 |
|-----|------|----------|
| **kubent (Kube-No-Trouble)** | [GitHub](https://github.com/doitintl/kube-no-trouble) | Deprecated API 검사 도구 |
| **Kubespray Releases** | [GitHub Releases](https://github.com/kubernetes-sigs/kubespray/releases) | 지원 Kubernetes 버전 |
| **Kubespray Variables** | [Variables Docs](https://kubespray.io/#/docs/ansible/vars) | 변수 변경사항 |
| **Kubernetes Changelog** | [CHANGELOG](https://github.com/kubernetes/kubernetes/tree/master/CHANGELOG) | 버전별 변경사항 |
| **Kubespray Upgrade Docs** | [Upgrade Guide](https://kubespray.io/#/docs/upgrades) | 공식 업그레이드 가이드 |
| **Kubernetes Deprecation Guide** | [Deprecated API Migration](https://kubernetes.io/docs/reference/using-api/deprecation-guide/) | API 마이그레이션 가이드 |

---

## 📎 부록: --limit 옵션 정리

| 옵션 | 대상 | 용도 |
|-----|------|------|
| `--limit "kube_control_plane"` | Control Plane 노드만 | Master 먼저 업그레이드 |
| `--limit "kube_node"` | 모든 Worker 노드 | Worker 업그레이드 |
| `--limit "kube_node:!kube_control_plane"` | 순수 Worker만 | Control Plane 제외 Worker |
| `--limit "k8s-worker-1"` | 특정 노드만 | 개별 노드 업그레이드 |
| `--limit "etcd"` | etcd 노드만 | External etcd 환경 |

---

## 📎 부록: Stacked etcd vs External etcd

| 구성 | 설명 | --limit 분리 필요? |
|-----|------|------------------|
| **Stacked etcd** | etcd가 Master 노드에 함께 있음 (기본값) | ❌ 불필요 |
| **External etcd** | etcd가 별도 노드에 있음 | ✅ 필요 |

현재 구성이 Stacked etcd인 경우 (etcd와 control_plane이 같은 노드):
- `--limit "kube_control_plane"` 만으로 etcd도 함께 업그레이드됩니다.
- `--limit "etcd"`를 별도로 실행할 필요 없습니다.
