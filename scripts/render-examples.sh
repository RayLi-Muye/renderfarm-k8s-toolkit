#!/usr/bin/env bash
set -euo pipefail

helm lint charts/render-worker

mkdir -p /tmp/rendered
helm template render-worker charts/render-worker >/tmp/rendered/default.yaml
helm template render-worker charts/render-worker -f examples/values-local.yaml >/tmp/rendered/local.yaml
helm template render-worker charts/render-worker -f examples/values-local-minio.yaml >/tmp/rendered/local-minio.yaml
helm template render-worker charts/render-worker -f examples/values-aws-gpu-sqs.yaml >/tmp/rendered/aws-gpu-sqs.yaml
helm template render-worker charts/render-worker -f examples/values-security-hardening.yaml >/tmp/rendered/security-hardening.yaml

if command -v kubeconform >/dev/null 2>&1; then
  KUBE_VERSION="${KUBE_VERSION:-1.31.0}"
  CRD_CATALOG_REF="${CRD_CATALOG_REF:-1de95b7e9cb737ba46b14fa5a033fee2e47d90a3}"

  for manifest in /tmp/rendered/default.yaml /tmp/rendered/local.yaml /tmp/rendered/local-minio.yaml /tmp/rendered/aws-gpu-sqs.yaml /tmp/rendered/security-hardening.yaml; do
    echo "Validating ${manifest}"
    kubeconform -strict -summary \
      -kubernetes-version "${KUBE_VERSION}" \
      -schema-location default \
      -schema-location "https://raw.githubusercontent.com/datreeio/CRDs-catalog/${CRD_CATALOG_REF}/{{ .Group }}/{{ .ResourceKind }}_{{ .ResourceAPIVersion }}.json" \
      "${manifest}"
  done
fi

echo "Rendered examples:"
echo "  /tmp/rendered/default.yaml"
echo "  /tmp/rendered/local.yaml"
echo "  /tmp/rendered/local-minio.yaml"
echo "  /tmp/rendered/aws-gpu-sqs.yaml"
echo "  /tmp/rendered/security-hardening.yaml"
