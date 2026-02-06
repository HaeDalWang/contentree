#!/bin/bash
# 차트에는 CRD가 포함되어 있으나, Helm이 같은 릴리스에서 CR을 CRD보다 먼저 적용할 수 있어
# "no matches for kind ... ensure CRDs are installed first" 발생. CRD를 선적용해 순서 보장 (최초 1회).
set -e
CHART_VERSION="66.7.1"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update
helm show crds prometheus-community/kube-prometheus-stack --version "$CHART_VERSION" | kubectl apply -f -
echo "Prometheus Operator CRDs applied. 이제 helmfile apply 가능."
