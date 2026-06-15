#!/usr/bin/env bash
set -euo pipefail

helm lint charts/render-worker
helm template render-worker charts/render-worker -f examples/values-local.yaml >/tmp/render-worker-local.yaml
helm template render-worker charts/render-worker -f examples/values-aws-gpu-sqs.yaml >/tmp/render-worker-aws.yaml

echo "Rendered examples:"
echo "  /tmp/render-worker-local.yaml"
echo "  /tmp/render-worker-aws.yaml"

