#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHART_DIR="${ROOT_DIR}/charts/render-worker"
TMP_DIR="$(mktemp -d)"
HELM="${HELM:-helm}"
trap 'rm -rf "${TMP_DIR}"' EXIT

render_chart() {
  local output_file="$1"
  shift
  "${HELM}" template render-worker "${CHART_DIR}" "$@" >"${output_file}"
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  local message="$3"

  if ! grep -Fq "${pattern}" "${file}"; then
    echo "missing expected output: ${message}" >&2
    echo "pattern: ${pattern}" >&2
    exit 1
  fi
}

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  local message="$3"

  if grep -Fq "${pattern}" "${file}"; then
    echo "unexpected output: ${message}" >&2
    echo "pattern: ${pattern}" >&2
    exit 1
  fi
}

expect_lint_failure() {
  local name="$1"
  local values_file="$2"
  local log_file="${TMP_DIR}/${name}.log"

  if "${HELM}" lint "${CHART_DIR}" -f "${values_file}" >"${log_file}" 2>&1; then
    echo "expected Helm lint to fail for ${name}" >&2
    cat "${log_file}" >&2
    exit 1
  fi
}

default_manifest="${TMP_DIR}/default.yaml"
local_manifest="${TMP_DIR}/local.yaml"
aws_manifest="${TMP_DIR}/aws-gpu-sqs.yaml"

render_chart "${default_manifest}"
assert_contains "${default_manifest}" "kind: Deployment" "default chart renders a worker Deployment"
assert_contains "${default_manifest}" "replicas: 0" "default chart keeps workers scaled to zero without KEDA"
assert_not_contains "${default_manifest}" "kind: ScaledObject" "default chart does not render KEDA"
assert_not_contains "${default_manifest}" "nvidia.com/gpu" "default chart does not request GPU resources"

render_chart "${local_manifest}" -f "${ROOT_DIR}/examples/values-local.yaml"
assert_contains "${local_manifest}" "replicas: 1" "local example renders one worker replica"
assert_not_contains "${local_manifest}" "kind: ScaledObject" "local example does not render KEDA"
assert_not_contains "${local_manifest}" "nvidia.com/gpu" "local example does not request GPU resources"

render_chart "${aws_manifest}" -f "${ROOT_DIR}/examples/values-aws-gpu-sqs.yaml"
assert_contains "${aws_manifest}" "kind: ScaledObject" "AWS example renders KEDA ScaledObject"
assert_contains "${aws_manifest}" "kind: TriggerAuthentication" "AWS example renders KEDA TriggerAuthentication"
assert_contains "${aws_manifest}" "nvidia.com/gpu: \"1\"" "AWS example requests one GPU"
assert_not_contains "${aws_manifest}" "replicas:" "AWS KEDA example leaves replica count to autoscaling"

cat >"${TMP_DIR}/invalid-replica.yaml" <<'YAML'
replicaCount: -1
YAML
expect_lint_failure "invalid-replica" "${TMP_DIR}/invalid-replica.yaml"

cat >"${TMP_DIR}/invalid-gpu-count.yaml" <<'YAML'
gpu:
  enabled: true
  count: 0
YAML
expect_lint_failure "invalid-gpu-count" "${TMP_DIR}/invalid-gpu-count.yaml"

cat >"${TMP_DIR}/invalid-image-pull-policy.yaml" <<'YAML'
image:
  pullPolicy: Sometimes
YAML
expect_lint_failure "invalid-image-pull-policy" "${TMP_DIR}/invalid-image-pull-policy.yaml"

cat >"${TMP_DIR}/invalid-postprocess-pull-policy.yaml" <<'YAML'
postprocessJob:
  enabled: true
  image:
    pullPolicy: Sometimes
YAML
expect_lint_failure "invalid-postprocess-pull-policy" "${TMP_DIR}/invalid-postprocess-pull-policy.yaml"

echo "Chart contract tests passed"
