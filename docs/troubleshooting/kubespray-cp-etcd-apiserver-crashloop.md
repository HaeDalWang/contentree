# Kubespray CP 노드 etcd / kube-apiserver CrashLoopBackOff

## 증상

- `kubectl get pod -A` 에서 **etcd-mvd-kubecp02**, **etcd-mvd-kubecp03**, **kube-apiserver-mvd-kubecp02**, **kube-apiserver-mvd-kubecp03** 이 CrashLoopBackOff.
- **calico-node** 전부 0/1 Ready, **calico-kube-controllers** CrashLoopBackOff.
- mvd-kubecp01 의 etcd / apiserver / controller-manager / scheduler 는 1/1 Running.

---

## 원인 순서

1. **etcd** 가 cp02/cp03에서 실패하면 해당 노드의 **kube-apiserver** 도 local etcd(127.0.0.1:2379)에 붙지 못해 같이 실패.
2. etcd 실패 흔한 원인: 클러스터 미형성(초기 클러스터 목록/네트워크), 인증서, 디스크/리소스.
3. calico-node 0/1 / calico-kube-controllers 실패는 CP가 안정화되면 해소되는 경우가 많음.

---

## 1단계: 로그로 원인 확인

**mvd-kubecp01** 에서 실행 (kubectl 사용 가능한 곳):

```bash
# etcd cp02/cp03 — 왜 재시작하는지
kubectl logs -n kube-system etcd-mvd-kubecp02 --tail=80
kubectl logs -n kube-system etcd-mvd-kubecp03 --tail=80

# 이전 크래시 로그까지 보려면
kubectl logs -n kube-system etcd-mvd-kubecp02 --previous --tail=80 2>/dev/null || true

# 이벤트(스케줄링/실행 실패 등)
kubectl describe pod -n kube-system etcd-mvd-kubecp02 | tail -30
kubectl describe pod -n kube-system etcd-mvd-kubecp03 | tail -30
```

apiserver는 etcd가 뜨기 전에는 의미 있는 로그가 나오기 어렵다. **우선 etcd 로그**에 나오는 메시지 확인.

| 로그/메시지 예시 | 추정 원인 |
|------------------|-----------|
| `connection refused` / `dial tcp ... 2379` | 다른 etcd 멤버(cp01)에 접근 불가 → 네트워크 또는 방화벽 |
| `etcd cluster is unavailable` / `no leader` | 초기 클러스터 미형성, 조인 미완료 |
| `certificate ... not valid` / `x509` | 인증서 SAN 또는 만료/호스트명 불일치 |
| `no space left` / `disk pressure` | 디스크 부족 (노드 `df -h` 확인) |
| `listen tcp 10.150.46.16:2381: bind: cannot assign requested address` | cp02/cp03에 첫 CP IP로 메트릭 바인드 시도 → [아래 5단계](#5단계-etcd-2381-bind-실패-수정) 참고 |

---

## 2단계: 네트워크 확인

cp02/cp03에서 cp01의 etcd(2380/2379) 접근 가능 여부:

```bash
# mvd-kubecp02에 SSH 후
nc -zv 10.150.46.16 2379
nc -zv 10.150.46.16 2380
```

실패 시: 10.150.46.0/24 내부 2379, 2380 허용(보안 그룹/방화벽) 확인.

---

## 3단계: 수리 — cluster.yml 재실행 (권장)

조인 직후 타이밍 이슈로 etcd가 클러스터를 못 만든 경우, **첫 CP가 이미 안정된 상태에서** cluster.yml을 다시 실행하면 cp02/cp03 etcd/apiserver가 정상 기동하는 경우가 많다.

(Kubespray 컨테이너 또는 Ansible 실행 환경에서)

```bash
# 컨테이너 안이면 예:
cd /kubespray
ansible-playbook -i inventory/inventory.yaml -e @inventory/variables-1.29.yaml --become cluster.yml
```

또는 인벤토리용 run.sh가 있다면:

```bash
bash /kubespray/inventory/run.sh
```

재실행 후:

```bash
kubectl get pod -n kube-system -l component=etcd
kubectl get pod -n kube-system -l component=kube-apiserver
```

둘 다 cp01/cp02/cp03에서 Running 이면, calico-node / calico-kube-controllers 도 시간 두고 Ready 되는지 확인.

---

## 5단계: etcd 2381 bind 실패 수정

에러가 `listen tcp 10.150.46.16:2381: bind: cannot assign requested address` 인 경우, kubeadm join 시 cp02/cp03에 **첫 CP IP(10.150.46.16)** 로 메트릭 리스닝 주소가 들어가서 해당 노드에서 바인드 불가한 상태다.

**조치:** `inventory/variables-1.29.yaml` 에서 etcd 메트릭을 노드 자신 IP 대신 **0.0.0.0** 으로 바인드하도록 변경한 뒤 cluster.yml 재실행.

```yaml
etcd_extra_vars:
  listen-metrics-urls: "http://0.0.0.0:{{ etcd_metrics_port }}"
```

변경 반영 후 `cluster.yml` 재실행하면 etcd static pod manifest 가 갱신되고, cp02/cp03 etcd가 정상 기동한다.

---

## 4단계: 회피 — POC에서 CP 1대로 운영

HA가 필요 없으면 인벤토리에서 **kube_control_plane** 을 mvd-kubecp01 만 남기고, cp02/cp03는 worker로만 쓰거나 제거한 뒤 클러스터 재설치.  
자세한 내용은 [kubespray-control-plane-join-failed.md](./kubespray-control-plane-join-failed.md) 4번 참고.

---

## 요약

| 순서 | 작업 | 목적 |
|------|------|------|
| 1 | `kubectl logs` / `describe` 로 etcd-mvd-kubecp02, 03 확인 | 실제 에러 메시지 파악 |
| 2 | cp02에서 10.150.46.16:2379, 2380 연결 테스트 | 네트워크/방화벽 |
| 3 | cluster.yml 재실행 | 조인/타이밍 이슈 수리 |
| 4 | (선택) POC는 CP 1대로 재구성 | 조인 이슈 회피 |
