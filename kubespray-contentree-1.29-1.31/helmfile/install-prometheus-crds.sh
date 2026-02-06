#!/bin/bash
# helmfile은 diff 시 매니페스트를 먼저 렌더하는데, 이때 클러스터에 CRD가 없으면
# "no matches for kind Alertmanager/Prometheus..." 로 실패함 (이슈 #2217).
# helm install은 되지만 helmfile apply는 CRD 선설치 필요. 차트 패키지의 원본 CRD만
# 적용 (helm show crds 는 annotation 262144 bytes 초과로 실패하므로 사용 안 함).
set -e
CHART_VERSION="66.7.1"
REPO_URL="https://prometheus-community.github.io/helm-charts"
CHART_NAME="kube-prometheus-stack"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

helm repo add prometheus-community "$REPO_URL" 2>/dev/null || true
helm repo update
helm pull prometheus-community/"$CHART_NAME" --version "$CHART_VERSION" --untar -d "$TMP_DIR"
CRDS_DIR="$TMP_DIR/$CHART_NAME/charts/crds/crds"
if [ ! -d "$CRDS_DIR" ]; then
  echo "CRD 디렉토리를 찾을 수 없음: $CRDS_DIR" >&2
  exit 1
fi
kubectl apply -f "$CRDS_DIR"
echo "Prometheus Operator CRDs 적용 완료. 이제 helmfile apply 실행 가능."
