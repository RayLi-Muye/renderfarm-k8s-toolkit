#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

export MOCK_QUEUE_FILE="${ROOT_DIR}/examples/mock-queue.txt"
export MOCK_OUTPUT_DIR="${TMP_DIR}/output"
export MOCK_MANIFEST_DIR="${TMP_DIR}/manifest"

"${ROOT_DIR}/workers/mock-render-worker/mock-render-worker.sh" render
"${ROOT_DIR}/workers/mock-render-worker/mock-render-worker.sh" postprocess

expected_frames=3
actual_frames="$(find "${MOCK_OUTPUT_DIR}" -type f -name 'frame-*.txt' | wc -l | tr -d ' ')"

if [[ "${actual_frames}" != "${expected_frames}" ]]; then
  echo "expected ${expected_frames} rendered frames, found ${actual_frames}" >&2
  exit 1
fi

if ! grep -q '^frames=3$' "${MOCK_MANIFEST_DIR}/manifest.txt"; then
  echo "postprocess manifest does not report three frames" >&2
  exit 1
fi

unsafe_queue="${TMP_DIR}/unsafe-queue.txt"
unsafe_output="${TMP_DIR}/unsafe-output"
escape_path="${TMP_DIR}/escape/frame-0001.txt"
printf '../../escape|0001|public-demo-scene\n' >"${unsafe_queue}"

if MOCK_QUEUE_FILE="${unsafe_queue}" MOCK_OUTPUT_DIR="${unsafe_output}" \
  "${ROOT_DIR}/workers/mock-render-worker/mock-render-worker.sh" render >/dev/null 2>&1; then
  echo "unsafe queue identifiers were accepted" >&2
  exit 1
fi

if [[ -e "${escape_path}" ]]; then
  echo "unsafe queue identifiers wrote outside the output directory" >&2
  exit 1
fi

echo "Local mock smoke test passed"
