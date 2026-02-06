# Kubespray "Joining control plane node to the cluster" 실패

## 증상

- `FAILED - RETRYING: [mvd-kubecp02]: Joining control plane node to the cluster. (3 retries left).`
- 2번째·3번째 CP 노드(mvd-kubecp02, mvd-kubecp03) 조인 시 재시도 후 실패.

---

## 예상 원인 (다수 사용자 동일 이슈)

Kubespray/커뮤니티에서 자주 보고되는 원인은 아래와 같다.

1. **타이밍(가장 흔함)**  
   첫 번째 CP(mvd-kubecp01)의 etcd·apiserver가 완전히 기동되기 전에 cp02/cp03이 조인을 시도함. 재시도 간 대기 시간이 짧으면 계속 실패.

2. **cluster-info RBAC (anonymous auth)**  
   kubeadm join이 `kube-public` 네임스페이스의 `cluster-info` ConfigMap을 anonymous로 읽음.  
   `kube_api_anonymous_auth: false`이면 `User "system:anonymous" cannot get resource "configmaps"` 로 실패.  
   → **현재 variables-1.29.yaml에는 `kube_api_anonymous_auth: true` 로 이미 설정됨.**

3. **네트워크**  
   cp02, cp03에서 apiserver 주소(현재 10.150.46.16)로 6443 포트 접근 불가.  
   (보안 그룹, NACL, 방화벽 등)

4. **인증서 SAN**  
   첫 CP가 발급한 apiserver 인증서에 조인 시 사용하는 주소(10.150.46.16)가 SAN에 포함되어 있지 않으면 TLS 검증 실패.  
   LB 없이 단일 IP로 설정한 경우 보통 문제 없음.

5. **Kubespray 버그 (이슈 #10973)**  
   일부 버전에서 `kubeadm_certificate_key`를 `groups['kube_control_plane'][0]`가 아닌 `first_kube_control_plane`로 참조해야 하는데 잘못 참조해, 2번째 CP 조인 시 실패하는 케이스가 있음.  
   v2.24.3에 해당 패치 포함 여부는 Kubespray 릴리스/커밋 확인 필요.

---

## 해결 방법

### 1. 상세 로그로 실제 에러 확인

컨테이너 안에서 재실행 시 verbosity 올리기:

```bash
ansible-playbook -i inventory/inventory.yaml \
  -e @inventory/variables-1.29.yaml \
  --become --become-user=root \
  -vvv cluster.yml
```

실패한 태스크 근처의 **stderr/실제 에러 메시지**를 확인한다.

- `connection refused` / `timeout` → 네트워크 또는 첫 CP 미기동(타이밍).
- `forbidden ... system:anonymous ... cluster-info` → anonymous auth 또는 RBAC.
- `certificate ... not valid` → 인증서 SAN 또는 주소 불일치.
- `kubeadm_certificate_key is undefined` → Kubespray 버그(아래 4번 참고).

### 2. 네트워크 확인

cp02에서 첫 CP(10.150.46.16) 6443 접근 가능 여부:

```bash
# mvd-kubecp02(10.150.46.17)에 SSH 접속 후
curl -k https://10.150.46.16:6443/version
# 또는
nc -zv 10.150.46.16 6443
```

실패 시: AWS 보안 그룹에서 10.150.46.0/24(또는 해당 VPC CIDR) → 6443 허용 여부 확인.

### 3. 재시도만으로 성공하는 경우

타이밍 이슈일 수 있으므로 **그대로 cluster.yml을 한 번 더 실행**해 본다.  
첫 CP가 이미 안정화된 상태에서 재실행하면 cp02/cp03 조인이 성공하는 경우가 많다.

```bash
bash /kubespray/inventory/run.sh
```

### 4. POC에서 1 CP만 쓰기 (회피)

업그레이드 POC만 할 경우, **인벤토리에서 CP를 1대만 두고** 설치하면 조인 실패 자체가 없다.

- `inventory.yaml`의 `kube_control_plane`를 `mvd-kubecp01`만 남기고,  
  클러스터 설치 완료 후 필요 시 1.31 업그레이드까지 1 CP로 진행.
- HA 검증이 필요해지면 그때 CP 3대로 다시 구성하고, 위 1~3번을 적용.

### 5. Kubespray 버전/패치

`kubeadm_certificate_key is undefined` 또는 `first_kube_control_plane` 관련 에러가 로그에 나오면,  
[Kubespray #10973](https://github.com/kubernetes-sigs/kubespray/issues/10973) 및 PR #11875 이 반영된 버전으로 올리거나,  
해당 패치를 수동으로 적용한 뒤 다시 시도한다.

---

## 요약

| 원인           | 확인 방법                    | 대응 |
|----------------|-----------------------------|------|
| 타이밍         | 재실행 시 성공 여부         | cluster.yml 재실행 또는 재시도 대기 시간 증가 |
| anonymous auth | variables에 `kube_api_anonymous_auth: true` | 이미 true면 다른 원인 |
| 네트워크       | cp02에서 10.150.46.16:6443 접근 | 보안 그룹/방화벽 수정 |
| Kubespray 버그 | -vvv 로 `kubeadm_certificate_key` 등 에러 확인 | 버전 업 또는 패치 적용 |
| 회피           | -                           | POC는 CP 1대로 설치 |

**우선:** `-vvv`로 실패 시점의 정확한 에러 메시지를 확인한 뒤, 위 표와 해결 방법을 대입해 보는 것이 좋다.
