# renderfarm-k8s-toolkit

Reusable Kubernetes building blocks for GPU-backed render worker orchestration on AWS.

This repository is a public engineering reconstruction of a render-farm orchestration layer. It does not contain employer source code, customer assets, V-Ray binaries, license files, cloud account identifiers, or production secrets.

## What This Demonstrates

This project demonstrates production-shaped cloud infrastructure work in a public-safe form: reusable Helm packaging, queue-driven worker orchestration, GPU scheduling controls, AWS/EKS integration points, CI validation, and explicit public/private safety boundaries.

For reviewers, the intended signal is not a toy renderer. It is the orchestration layer around private render workers: how workloads are packaged, scaled, scheduled, validated, documented, and separated from proprietary assets.

## Scope

The first reusable component is a Helm chart for render worker orchestration:

- GPU-backed worker `Deployment` for render workloads.
- Optional KEDA `ScaledObject` for SQS backlog driven scaling.
- Optional KEDA `TriggerAuthentication` for pod-identity based SQS scaler access.
- Kubernetes `Job` template for post-render processing.
- `ServiceAccount` annotations for IRSA or EKS Pod Identity style integrations.
- ConfigMap and Secret injection points.
- Node scheduling controls for GPU, CPU, Spot, and post-processing pools.
- Example values files for local and AWS/EKS-style deployments.

The chart is renderer-agnostic. A V-Ray worker image can be used in a private environment, but this repository only provides orchestration primitives.

## Architecture

```text
Render API or DCC submitter
        |
        | enqueue frame/task messages
        v
Amazon SQS or compatible queue
        |
        | backlog drives scaling
        v
KEDA ScaledObject
        |
        v
Kubernetes worker Pods
        |
        | read assets / render / upload outputs
        v
S3 or compatible object storage
        |
        v
Post-processing Job
```

## Quickstart

Install Helm, then render the default chart:

```bash
helm lint charts/render-worker
helm template render-worker charts/render-worker -f examples/values-aws-gpu-sqs.yaml
```

The default chart is safe for public review: KEDA is disabled in `values.yaml`, no secrets are populated, and no cloud resources are created by Helm.

## Reviewer Path

1. Run `make lint` and `make template`.
2. Inspect [docs/evidence-map.md](docs/evidence-map.md) for claim-to-file references.
3. Read [docs/architecture.md](docs/architecture.md) for scope boundaries and production integrations.
4. Check open issues for the next hardening nodes and merged pull requests for review history.

## Development Workflow

This repo uses GitHub features intentionally:

- Issues track independently shippable engineering tasks.
- Pull requests are used even for solo work to preserve reviewable history.
- GitHub Actions runs chart linting and template rendering.
- Issue and PR templates force clear acceptance criteria.

See [docs/development.md](docs/development.md) and [docs/roadmap.md](docs/roadmap.md).

## Delivery Nodes

Future work is tracked as GitHub issues and written so another contributor or agent can continue from a clean handoff. See [docs/delivery-prompts.md](docs/delivery-prompts.md) for continuation prompts.

## Resume Evidence

See [docs/evidence-map.md](docs/evidence-map.md) for how this repository maps to Kubernetes, EKS, GPU worker orchestration, S3 asset flows, KEDA/SQS scaling, and CI/CD resume claims.

## Safety

- Do not commit real customer assets.
- Do not commit V-Ray binaries or license files.
- Do not commit AWS access keys or account identifiers.
- Keep production-specific values in private deployment repos or secret managers.
