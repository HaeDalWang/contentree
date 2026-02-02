# Kubespray 버전 호환성 트러블슈팅

## 개요

Kubespray를 사용하여 Kubernetes 클러스터를 배포할 때 발생할 수 있는 버전 호환성 문제와 해결 방법을 정리합니다.

---

## 케이스 1: `downloads.runc` undefined 에러

### 증상

```
TASK [container-engine/runc : Download_file | Show url of file to dowload]
fatal: [k8s-master-1]: FAILED! => {
    "msg": "The task includes an option with an undefined variable. 
    The error was: {{ download_defaults | combine(downloads.runc) }}: ...
}
```

### 원인

**Kubespray 버전에서 지원하지 않는 Kubernetes 버전을 지정한 경우 발생**

- 예: Kubespray v2.26.0에서 `kube_version: v1.29.15` 사용 시 에러 발생
- Kubespray 각 버전은 특정 범위의 Kubernetes 버전만 지원하며, 해당 버전에 대한 checksum 및 다운로드 URL이 정의되어 있어야 함

### 해결 방법

1. **Kubespray 버전별 지원 Kubernetes 버전 확인**

   ```bash
   # 컨테이너 내부에서 지원 버전 확인
   cat /kubespray/roles/kubespray-defaults/defaults/main/main.yml | grep kube_version
   cat /kubespray/roles/kubespray-defaults/defaults/main/checksums.yml | grep -A5 "kube_version"
   ```

2. **지원되는 버전 사용**

   | Kubespray 버전 | 기본 Kubernetes 버전 | 지원 범위 |
   |---------------|---------------------|----------|
   | v2.26.0       | v1.30.4             | v1.29.x ~ v1.30.x |
   | v2.25.0       | v1.29.x             | v1.28.x ~ v1.29.x |
   | v2.24.0       | v1.28.x             | v1.27.x ~ v1.28.x |

   > 정확한 지원 버전은 [Kubespray GitHub Releases](https://github.com/kubernetes-sigs/kubespray/releases) 참조

3. **variables.yaml 수정**

   ```yaml
   # 잘못된 설정 (지원하지 않는 버전)
   kube_version: v1.29.15
   
   # 올바른 설정 (Kubespray v2.26.0 기본값 사용)
   kube_version: v1.30.4
   ```

### 예방 방법

- Kubespray 버전 선택 시 배포하려는 Kubernetes 버전 지원 여부 먼저 확인
- `variables.yaml`에 버전 명시 전 `checksums.yml`에 해당 버전 checksum 존재 여부 확인
- Kubespray GitHub Issues에서 버전 관련 이슈 검색

---

## 케이스 2: group_vars 누락 에러

### 증상

```
[WARNING]: Unable to parse /kubespray/inventory/inventory.yaml as an inventory source
```

또는 `deploy_netchecker`, `netcheck_server_image_repo` 등 변수 undefined 에러

### 원인

Kubespray는 `inventory/group_vars/` 디렉토리의 설정 파일들을 필요로 함. 커스텀 inventory 사용 시 `group_vars/`가 누락되면 기본 변수들이 로드되지 않음.

### 해결 방법

```bash
# sample의 group_vars를 inventory로 복사
cp -r /kubespray/inventory/sample/group_vars /kubespray/inventory/
```

### 예방 방법

`kubespray.sh` 스크립트에서 컨테이너 시작 시 자동으로 `group_vars` 초기화:

```bash
# 컨테이너 시작 후 group_vars 초기화
docker exec kubespray bash -c '
  if [ ! -d "/kubespray/inventory/group_vars" ]; then
    cp -r /kubespray/inventory/sample/group_vars /kubespray/inventory/
    echo "group_vars 복사 완료"
  fi
'
```

---

## 케이스 3: extra-vars 경로 에러

### 증상

```
ERROR! Unable to retrieve file contents
Could not find or access '/inventory/variables.yaml' on the Ansible Controller.
```

### 원인

`--extra-vars "@/inventory/variables.yaml"`에서 `@` 뒤에 `/`가 붙으면 **절대 경로**로 해석됨.

### 해결 방법

```bash
# 잘못된 경로 (절대 경로 - 루트의 /inventory)
--extra-vars "@/inventory/variables.yaml"

# 올바른 경로 (상대 경로)
--extra-vars "@inventory/variables.yaml"
```

---

## 참고 링크

- [Kubespray GitHub Repository](https://github.com/kubernetes-sigs/kubespray)
- [Kubespray Releases & Compatibility Matrix](https://github.com/kubernetes-sigs/kubespray/releases)
- [Kubespray Issues](https://github.com/kubernetes-sigs/kubespray/issues)
