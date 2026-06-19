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
minio_manifest="${TMP_DIR}/local-minio.yaml"
security_manifest="${TMP_DIR}/security-hardening.yaml"

render_chart "${default_manifest}"
assert_contains "${default_manifest}" "kind: Deployment" "default chart renders a worker Deployment"
assert_contains "${default_manifest}" "replicas: 0" "default chart keeps workers scaled to zero without KEDA"
assert_not_contains "${default_manifest}" "kind: ScaledObject" "default chart does not render KEDA"
assert_not_contains "${default_manifest}" "kind: NetworkPolicy" "default chart does not render NetworkPolicy"
assert_not_contains "${default_manifest}" "nvidia.com/gpu" "default chart does not request GPU resources"

render_chart "${local_manifest}" -f "${ROOT_DIR}/examples/values-local.yaml"
assert_contains "${local_manifest}" "replicas: 1" "local example renders one worker replica"
assert_contains "${local_manifest}" "\"helm.sh/hook\": \"post-install,post-upgrade\"" "local postprocess Job uses Helm hook ownership"
assert_contains "${local_manifest}" "\"helm.sh/hook-delete-policy\": \"before-hook-creation,hook-succeeded\"" "local postprocess hook deletes old Jobs before upgrades"
assert_contains "${local_manifest}" "value: \"local-queue\"" "local queue adapter renders worker queue env"
assert_contains "${local_manifest}" "value: \"local-assets\"" "local storage adapter renders asset env"
assert_contains "${local_manifest}" "value: \"local-output\"" "local storage adapter renders output env"
assert_not_contains "${local_manifest}" "kind: ScaledObject" "local example does not render KEDA"
assert_not_contains "${local_manifest}" "nvidia.com/gpu" "local example does not request GPU resources"

render_chart "${minio_manifest}" -f "${ROOT_DIR}/examples/values-local-minio.yaml"
assert_contains "${minio_manifest}" "name: render-worker-credentials" "existingSecret identity adapter renders a Secret reference"
assert_contains "${minio_manifest}" "name: STORAGE_ENDPOINT" "MinIO storage adapter renders endpoint env"
assert_contains "${minio_manifest}" "value: \"render-assets\"" "MinIO storage adapter renders asset bucket env"
assert_contains "${minio_manifest}" "value: \"render-output\"" "MinIO storage adapter renders output bucket env"

render_chart "${aws_manifest}" -f "${ROOT_DIR}/examples/values-aws-gpu-sqs.yaml"
assert_contains "${aws_manifest}" "kind: ScaledObject" "AWS example renders KEDA ScaledObject"
assert_contains "${aws_manifest}" "kind: TriggerAuthentication" "AWS example renders KEDA TriggerAuthentication"
assert_contains "${aws_manifest}" "\"helm.sh/hook\": \"post-install,post-upgrade\"" "AWS postprocess Job uses Helm hook ownership"
assert_contains "${aws_manifest}" "\"helm.sh/hook-weight\": \"0\"" "AWS postprocess hook renders a deterministic hook weight"
assert_contains "${aws_manifest}" "nvidia.com/gpu: \"1\"" "AWS example requests one GPU"
assert_contains "${aws_manifest}" "eks.amazonaws.com/role-arn: arn:aws:iam::000000000000:role/render-worker-irsa" "IRSA identity adapter renders ServiceAccount annotation"
assert_contains "${aws_manifest}" "value: \"https://sqs.us-east-1.amazonaws.com/000000000000/render-frames\"" "SQS queue adapter renders worker queue env"
assert_contains "${aws_manifest}" "queueURLFromEnv: \"QUEUE_URL\"" "SQS queue adapter drives KEDA queueURLFromEnv"
assert_contains "${aws_manifest}" "karpenter.sh/nodepool: render-gpu" "AWS example schedules workers onto the GPU node pool"
assert_contains "${aws_manifest}" "render.node/type: gpu-render" "AWS example labels workers for GPU render nodes"
assert_contains "${aws_manifest}" "value: cpu-postprocess" "AWS example tolerates CPU postprocess nodes"
assert_contains "${aws_manifest}" "karpenter.sh/nodepool: render-cpu" "AWS example schedules postprocess jobs onto the CPU node pool"
assert_contains "${aws_manifest}" "karpenter.sh/capacity-type" "AWS example includes a postprocess capacity-type affinity hint"
assert_not_contains "${aws_manifest}" "replicas:" "AWS KEDA example leaves replica count to autoscaling"

render_chart "${security_manifest}" -f "${ROOT_DIR}/examples/values-security-hardening.yaml"
assert_contains "${security_manifest}" "kind: NetworkPolicy" "security example renders a NetworkPolicy"
assert_contains "${security_manifest}" "name: render-worker-egress-boundary" "security example uses an explicit NetworkPolicy name"
assert_contains "${security_manifest}" "eks.amazonaws.com/role-arn: arn:aws:iam::000000000000:role/render-worker-irsa" "security example keeps IRSA role ARN as a placeholder"
assert_contains "${security_manifest}" "workload.renderfarm.dev/type: worker" "security NetworkPolicy selects worker pods"
assert_contains "${security_manifest}" "renderfarm.dev/network-role: aws-egress-gateway" "security example scopes egress through a placeholder gateway"
assert_not_contains "${security_manifest}" "AWS_ACCESS_KEY_ID" "security example does not inject static AWS access keys"
assert_not_contains "${security_manifest}" "AWS_SECRET_ACCESS_KEY" "security example does not inject static AWS secret keys"
assert_not_contains "${security_manifest}" "kind: Secret" "security example does not create a Kubernetes Secret"

cat >"${TMP_DIR}/managed-postprocess.yaml" <<'YAML'
postprocessJob:
  enabled: true
  mode: managed
YAML
managed_postprocess_manifest="${TMP_DIR}/managed-postprocess-rendered.yaml"
render_chart "${managed_postprocess_manifest}" -f "${TMP_DIR}/managed-postprocess.yaml"
assert_contains "${managed_postprocess_manifest}" "kind: Job" "managed mode still renders a Job"
assert_not_contains "${managed_postprocess_manifest}" "helm.sh/hook" "managed postprocess Job is Helm release-owned, not a hook"

cat >"${TMP_DIR}/pod-identity-adapter.yaml" <<'YAML'
keda:
  enabled: true
  authentication:
    enabled: true
adapters:
  identity:
    type: podIdentity
    podIdentity:
      provider: aws-eks
YAML
pod_identity_manifest="${TMP_DIR}/pod-identity-adapter-rendered.yaml"
render_chart "${pod_identity_manifest}" -f "${TMP_DIR}/pod-identity-adapter.yaml"
assert_contains "${pod_identity_manifest}" "provider: \"aws-eks\"" "podIdentity identity adapter drives KEDA TriggerAuthentication provider"

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

cat >"${TMP_DIR}/invalid-postprocess-mode.yaml" <<'YAML'
postprocessJob:
  enabled: true
  mode: generatedName
YAML
expect_lint_failure "invalid-postprocess-mode" "${TMP_DIR}/invalid-postprocess-mode.yaml"

cat >"${TMP_DIR}/invalid-postprocess-hook-event.yaml" <<'YAML'
postprocessJob:
  enabled: true
  hook:
    events:
      - during-upgrade
YAML
expect_lint_failure "invalid-postprocess-hook-event" "${TMP_DIR}/invalid-postprocess-hook-event.yaml"

cat >"${TMP_DIR}/invalid-postprocess-hook-delete-policy.yaml" <<'YAML'
postprocessJob:
  enabled: true
  hook:
    deletePolicy:
      - keep-forever
YAML
expect_lint_failure "invalid-postprocess-hook-delete-policy" "${TMP_DIR}/invalid-postprocess-hook-delete-policy.yaml"

cat >"${TMP_DIR}/invalid-queue-adapter.yaml" <<'YAML'
adapters:
  queue:
    type: rabbitmq
YAML
expect_lint_failure "invalid-queue-adapter" "${TMP_DIR}/invalid-queue-adapter.yaml"

cat >"${TMP_DIR}/invalid-storage-adapter.yaml" <<'YAML'
adapters:
  storage:
    type: ftp
YAML
expect_lint_failure "invalid-storage-adapter" "${TMP_DIR}/invalid-storage-adapter.yaml"

cat >"${TMP_DIR}/invalid-identity-adapter.yaml" <<'YAML'
adapters:
  identity:
    type: staticCredentials
YAML
expect_lint_failure "invalid-identity-adapter" "${TMP_DIR}/invalid-identity-adapter.yaml"

cat >"${TMP_DIR}/invalid-network-policy-type.yaml" <<'YAML'
networkPolicy:
  enabled: true
  policyTypes:
    - External
YAML
expect_lint_failure "invalid-network-policy-type" "${TMP_DIR}/invalid-network-policy-type.yaml"

cat >"${TMP_DIR}/worker-env-override.yaml" <<'YAML'
adapters:
  queue:
    type: mock
    mock:
      queueName: adapter-queue
worker:
  env:
    QUEUE_URL: override-queue
YAML
override_manifest="${TMP_DIR}/worker-env-override-rendered.yaml"
render_chart "${override_manifest}" -f "${TMP_DIR}/worker-env-override.yaml"
assert_contains "${override_manifest}" "value: \"override-queue\"" "worker.env overrides adapter-generated env"
assert_not_contains "${override_manifest}" "value: \"adapter-queue\"" "adapter env is replaced by worker.env override"

echo "Chart contract tests passed"
