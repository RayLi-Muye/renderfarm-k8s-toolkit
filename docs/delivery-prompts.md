# Delivery Prompts

Use these prompts to continue development from a fresh checkout. Each prompt is scoped to one GitHub issue and one pull request.

## Node: Chart Adapter Seams

```text
Repository: RayLi-Muye/renderfarm-k8s-toolkit
Issue: #12 Define chart adapter seams for queue, storage, and identity

This node has been implemented with public values interfaces for queue, storage, and identity adapters while preserving the AWS GPU/SQS example.

Implemented files:
- charts/render-worker/values.yaml
- charts/render-worker/values.schema.json
- charts/render-worker/templates/_helpers.tpl
- charts/render-worker/templates/deployment.yaml
- charts/render-worker/templates/keda-scaledobject.yaml
- charts/render-worker/templates/serviceaccount.yaml
- examples/*
- docs/architecture.md
- docs/evidence-map.md
- scripts/chart-contract-tests.sh

Validation:
- helm lint charts/render-worker
- helm template render-worker charts/render-worker
- helm template render-worker charts/render-worker -f examples/values-local.yaml
- helm template render-worker charts/render-worker -f examples/values-local-minio.yaml
- helm template render-worker charts/render-worker -f examples/values-aws-gpu-sqs.yaml
- make test

Follow-up direction:
- Add deeper adapter-specific negative tests if the values schema becomes conditional.
- Add a richer local object-store demo only if it remains public-safe and credential-free.
```

## Node: Kubeconform and Install Integrity

```text
Repository: RayLi-Muye/renderfarm-k8s-toolkit
Issue: #15 Add kubeconform validation and Helm install integrity checks

This node has been implemented. Continue only if CI validation needs deeper policy checks.

Follow-up direction:
- Add negative chart rendering tests for invalid values.
- Add policy checks for securityContext, NetworkPolicy, and Secret usage.

Validation:
- CI passes on a PR.
- The workflow validates default, local, and AWS GPU/SQS rendered manifests.
- Helm and kubeconform installations are pinned and checksum-verified.
- KEDA CRDs are validated through a pinned CRD schema catalog.

Evidence update:
- Update docs/evidence-map.md for schema validation and CI hardening.
```

## Node: Chart Tests and Schema

```text
Repository: RayLi-Muye/renderfarm-k8s-toolkit
Issue: #3 Add chart unit tests and stronger values schema

This node has been implemented with local chart contract tests and additional values schema coverage. Continue only if the project needs a dedicated Helm test framework or deeper negative schema coverage.

Implemented files:
- scripts/chart-contract-tests.sh
- charts/render-worker/values.schema.json
- .github/workflows/ci.yml
- Makefile
- docs/development.md
- docs/evidence-map.md

Validation:
- `make test` checks GPU enabled/disabled rendering, KEDA enabled/disabled rendering, and schema rejection for invalid replica counts, GPU counts, and image pull policies.
- CI runs the chart contract tests on pull requests and main pushes.
```

## Node: Mock Render Worker

```text
Repository: RayLi-Muye/renderfarm-k8s-toolkit
Issue: #7 Add mock render worker and local smoke test path

This node has been implemented as a public-safe shell worker and local smoke test. Continue only if the demo needs a container image, Docker Compose path, or richer local queue/object-store substitute.

Implemented files:
- workers/mock-render-worker/*
- examples/*
- scripts/smoke-local.sh
- .github/workflows/ci.yml
- README.md
- docs/development.md
- docs/evidence-map.md

Validation:
- `make smoke-local` runs without AWS credentials, a real renderer, or a Kubernetes cluster.
- CI runs the lightweight mock path through `scripts/smoke-local.sh`.
- README and evidence map distinguish the mock worker from private production renderer images.
```

## Node: Security Hardening

```text
Repository: RayLi-Muye/renderfarm-k8s-toolkit
Issue: #5 Add security hardening examples for AWS permissions and secrets

Add public-safe security examples for AWS permissions, secrets, and network isolation.

Expected files:
- examples/*
- charts/render-worker/templates/*
- docs/architecture.md
- docs/evidence-map.md

Validation:
- Helm lint and template rendering pass.
- Security examples use placeholders only.
- Docs explain where production IAM, Secrets Manager, External Secrets, and NetworkPolicy decisions live.
```
