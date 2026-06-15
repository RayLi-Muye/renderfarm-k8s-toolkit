# Delivery Prompts

Use these prompts to continue development from a fresh checkout. Each prompt is scoped to one GitHub issue and one pull request.

## Node: Chart Adapter Seams

```text
Repository: RayLi-Muye/renderfarm-k8s-toolkit
Issue: #12 Define chart adapter seams for queue, storage, and identity

Implement a deeper public values interface for queue, storage, and identity adapters without breaking the current AWS GPU/SQS example.

Expected files:
- charts/render-worker/values.yaml
- charts/render-worker/values.schema.json
- charts/render-worker/templates/*
- examples/*
- docs/architecture.md
- docs/evidence-map.md

Validation:
- helm lint charts/render-worker
- helm template render-worker charts/render-worker
- helm template render-worker charts/render-worker -f examples/values-local.yaml
- helm template render-worker charts/render-worker -f examples/values-aws-gpu-sqs.yaml

Evidence update:
- Update docs/evidence-map.md with adapter claims, verification commands, status, and boundaries.
```

## Node: Kubeconform and Install Integrity

```text
Repository: RayLi-Muye/renderfarm-k8s-toolkit
Issue: #15 Add kubeconform validation and Helm install integrity checks

Add Kubernetes schema validation and Helm install integrity checks to GitHub Actions.

Expected files:
- .github/workflows/ci.yml
- scripts/render-examples.sh if useful
- docs/development.md
- docs/evidence-map.md

Validation:
- CI passes on a PR.
- The workflow validates default, local, and AWS GPU/SQS rendered manifests.
- Helm installation is pinned and integrity-checked.

Evidence update:
- Update docs/evidence-map.md for schema validation and CI hardening.
```

## Node: Mock Render Worker

```text
Repository: RayLi-Muye/renderfarm-k8s-toolkit
Issue: #7 Add mock render worker and local smoke test path

Add a public mock worker path that exercises the chart contract without proprietary renderer binaries.

Expected files:
- workers/mock-render-worker/*
- examples/*
- charts/render-worker/values.yaml if new env contract is needed
- .github/workflows/ci.yml if the smoke test runs in CI
- docs/architecture.md
- docs/evidence-map.md

Validation:
- Local smoke test runs without AWS credentials.
- CI runs at least one lightweight mock path if practical.
- README and evidence map clearly distinguish the mock worker from private production renderer images.
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
