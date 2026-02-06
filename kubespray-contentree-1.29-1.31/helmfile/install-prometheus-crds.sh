#!/bin/bash
# helmfile은 diff 시 매니페스트를 먼저 렌더하는데, 이때 클러스터에 CRD가 없으면
# "no matches for kind Alertmanager/Prometheus..." 로 실패함 (이슈 #2217).
# 차트 CRD는 metadata.annotations가 262144 bytes 초과해 그대로 apply 시 실패하므로 제거 후 적용.
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

# annotation 제거 (262144 bytes 제한 회피). yq 우선, 없으면 python3+PyYAML
strip_annotations() {
  local f="$1"
  if command -v yq &>/dev/null; then
    yq eval 'del(.metadata.annotations)' "$f"
  elif python3 -c "import yaml" 2>/dev/null; then
    python3 - "$f" <<'PY'
import sys, yaml
with open(sys.argv[1]) as fp:
    doc = yaml.safe_load(fp)
if doc and isinstance(doc, dict) and "metadata" in doc and isinstance(doc["metadata"], dict):
    doc["metadata"].pop("annotations", None)
print(yaml.dump(doc, default_flow_style=False, allow_unicode=True, sort_keys=False))
PY
  else
    echo "yq 또는 python3+PyYAML 필요. 설치 후 재실행." >&2
    exit 1
  fi
}

for f in "$CRDS_DIR"/*.yaml; do
  [ -f "$f" ] || continue
  strip_annotations "$f" | kubectl apply -f -
done
echo "Prometheus Operator CRDs 적용 완료. 이제 helmfile apply 실행 가능."
