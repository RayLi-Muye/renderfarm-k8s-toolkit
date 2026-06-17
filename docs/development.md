# Development

## Local Checks

Required tools:

- Helm 3
- Optional: kubeconform for Kubernetes schema validation

Commands:

```bash
make lint
make template
make template-local
make smoke-local
make test
```

`scripts/render-examples.sh` also validates rendered manifests with kubeconform when it is installed locally. CI installs Helm and kubeconform with pinned versions and SHA256 checksums, then validates built-in Kubernetes resources and KEDA CRDs through a pinned CRD schema catalog.

`make smoke-local` runs the public mock worker path from `workers/mock-render-worker/mock-render-worker.sh`. It consumes `examples/mock-queue.txt`, writes placeholder frame output, and creates a postprocess manifest without AWS credentials, a real renderer, or a Kubernetes cluster.

`make test` runs local chart contract tests for GPU enabled/disabled rendering, KEDA enabled/disabled rendering, and schema rejection for common invalid values.

## Branching

Use short feature branches:

```text
feature/keda-sqs-scaling
feature/postprocess-job-template
fix/chart-labels
```

## Pull Requests

Every PR should include:

- A narrow summary.
- Acceptance criteria.
- Rendered manifest evidence, when Helm templates changed.
- Security notes when touching Secrets, ServiceAccounts, or IAM-related annotations.
- Evidence-map updates when the PR changes reviewer-facing claims.
- A continuation prompt for the next delivery node.

## Issue Workflow

Issues should be small enough to implement and review independently. Prefer one issue per deliverable:

- Chart primitive.
- Example values.
- CI validation.
- Documentation.
- Security hardening.

## Loop Engineering

The preferred loop is:

```text
issue -> branch -> implementation -> local validation -> PR -> GitHub Actions -> merge -> evidence update -> next issue
```

Do not batch unrelated hardening, demo, and documentation work into one pull request unless the evidence update depends on all of them.
