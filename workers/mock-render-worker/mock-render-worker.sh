#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  mock-render-worker.sh render
  mock-render-worker.sh postprocess

Environment:
  MOCK_QUEUE_FILE     Local queue file. Defaults to examples/mock-queue.txt.
  MOCK_OUTPUT_DIR     Directory for rendered placeholder frames.
  MOCK_MANIFEST_DIR   Directory for postprocess manifests.
USAGE
}

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

is_safe_id() {
  [[ "${1}" =~ ^[A-Za-z0-9_-]+$ ]]
}

render_frames() {
  local root queue_file output_dir line job_id frame_id scene frame_path rendered_count

  root="$(repo_root)"
  queue_file="${MOCK_QUEUE_FILE:-${root}/examples/mock-queue.txt}"
  output_dir="${MOCK_OUTPUT_DIR:-${root}/.tmp/mock-render-output}"
  rendered_count=0

  if [[ ! -f "${queue_file}" ]]; then
    echo "queue file not found: ${queue_file}" >&2
    return 1
  fi

  mkdir -p "${output_dir}"

  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ -z "${line}" || "${line}" == \#* ]] && continue

    IFS='|' read -r job_id frame_id scene <<<"${line}"
    if [[ -z "${job_id:-}" || -z "${frame_id:-}" || -z "${scene:-}" ]]; then
      echo "invalid queue message: ${line}" >&2
      return 1
    fi
    if ! is_safe_id "${job_id}" || ! is_safe_id "${frame_id}"; then
      echo "unsafe queue identifier: ${line}" >&2
      return 1
    fi

    frame_path="${output_dir}/${job_id}/frame-${frame_id}.txt"
    mkdir -p "$(dirname "${frame_path}")"
    {
      echo "mock_render=true"
      echo "job_id=${job_id}"
      echo "frame_id=${frame_id}"
      echo "scene=${scene}"
      echo "status=rendered"
    } >"${frame_path}"
    rendered_count=$((rendered_count + 1))
  done <"${queue_file}"

  echo "Rendered ${rendered_count} mock frame(s) into ${output_dir}"
}

postprocess_frames() {
  local root output_dir manifest_dir manifest frame_count

  root="$(repo_root)"
  output_dir="${MOCK_OUTPUT_DIR:-${root}/.tmp/mock-render-output}"
  manifest_dir="${MOCK_MANIFEST_DIR:-${output_dir}/postprocess}"
  manifest="${manifest_dir}/manifest.txt"

  if [[ ! -d "${output_dir}" ]]; then
    echo "output directory not found: ${output_dir}" >&2
    return 1
  fi

  mkdir -p "${manifest_dir}"
  frame_count="$(find "${output_dir}" -type f -name 'frame-*.txt' | wc -l | tr -d ' ')"

  {
    echo "mock_postprocess=true"
    echo "frames=${frame_count}"
    find "${output_dir}" -type f -name 'frame-*.txt' | sort
  } >"${manifest}"

  echo "Wrote mock postprocess manifest to ${manifest}"
}

command="${1:-}"
case "${command}" in
  render)
    render_frames
    ;;
  postprocess)
    postprocess_frames
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
