# renderfarm-k8s-toolkit

Reusable Helm toolkit for GPU-backed render worker orchestration on Kubernetes and EKS.

This repository packages the public-safe Kubernetes layer around a render farm: worker pod contracts, queue-driven scaling, GPU scheduling, storage and identity seams, local smoke tests, and CI validation. It does not include private renderer binaries, customer scenes, license files, cloud account identifiers, or production secrets.

## Jump To

[What It Does](#what-it-does) |
[Who It Is For](#who-it-is-for) |
[Core Capabilities](#core-capabilities) |
[Quick Start](#quick-start) |
[Local Development](#local-development) |
[Architecture](#architecture) |
[Scheduling](#scheduling) |
[Security](#security) |
[Repository Map](#repository-map) |
[Roadmap](#roadmap) |
[Contributing](#contributing) |
[Safety Boundary](#safety-boundary)

## What It Does

`renderfarm-k8s-toolkit` defines a reusable Helm chart for running render workers on Kubernetes. The chart is renderer-agnostic: a private team can plug in a real renderer image and private infrastructure values, while this public repository keeps the orchestration contract reviewable without exposing proprietary assets.

The first reusable component is `charts/render-worker`, which models:

- render worker `Deployment` resources;
- optional KEDA scaling from SQS or compatible queue backlog;
- optional KEDA `TriggerAuthentication` for pod identity;
- Kubernetes `Job` resources for post-render processing;
- `ServiceAccount` annotations for IRSA or EKS Pod Identity style integrations;
- ConfigMap, Secret, queue, storage, and identity adapter seams;
- GPU, CPU, Spot, and post-processing node scheduling controls;
- local and AWS/EKS-style example values files.

## Who It Is For

This repo is useful for:

- platform engineers reviewing the Kubernetes boundary around private render workers;
- infrastructure maintainers who want a public-safe Helm chart contract before connecting real cloud resources;
- reviewers evaluating queue scaling, GPU scheduling, CI validation, and documentation discipline;
- agents or contributors continuing small GitHub-native maintenance tasks from issues.

It is not a full render manager, DCC integration, asset pipeline, AWS provisioning stack, or production deployment repo.

## Core Capabilities

| Capability | What to inspect |
| --- | --- |
| Helm chart contract | `charts/render-worker/values.yaml`, `values.schema.json`, and `templates/` |
| Queue scaling | KEDA `ScaledObject` and `TriggerAuthentication` templates |
| Adapter seams | queue, storage, and identity values in examples and helper templates |
| Local smoke path | `workers/mock-render-worker/`, `examples/mock-queue.txt`, and `make smoke-local` |
| Example manifests | `examples/values-local.yaml`, `examples/values-local-minio.yaml`, and `examples/values-aws-gpu-sqs.yaml` |
| Validation | `make test`, `scripts/render-examples.sh`, and GitHub Actions |
| Evidence map | `docs/evidence-map.md` |

## Quick Start

Install Helm 3, then render the default chart:

```bash
helm lint charts/render-worker
helm template render-worker charts/render-worker
```

Render the local and AWS-style examples:

```bash
make template-local
make template-minio
make template
```

Run the public mock worker smoke test without AWS credentials, a real renderer, or a Kubernetes cluster:

```bash
make smoke-local
```

The smoke path reads `examples/mock-queue.txt`, writes placeholder frame outputs, and creates a postprocess manifest. It validates the worker-facing contract while keeping real renderer binaries, license files, customer scenes, and cloud resources out of the repo.

## Local Development

Common validation commands:

```bash
make lint
make test
make smoke-local
scripts/render-examples.sh
git diff --check
```

`make test` runs chart contract tests for GPU/KEDA rendering behavior and values schema rejection. `scripts/render-examples.sh` renders the built-in examples and validates manifests with kubeconform when available. CI installs pinned Helm and kubeconform versions before running the same chart validation path.

See `docs/development.md` for the issue, branch, pull request, and validation workflow.

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

The chart renders Kubernetes resources only. It does not create SQS queues, S3 buckets, IAM roles, EKS clusters, node groups, renderer licenses, or production secrets.

For more detail, read `docs/architecture.md`.

## Postprocess Job Ownership

`postprocessJob.mode` defaults to `hook`. In hook mode the chart renders the
postprocess `Job` as a Helm `post-install,post-upgrade` hook with
`before-hook-creation,hook-succeeded` deletion. That keeps image, command, args,
env, and pod-template changes out of Helm's normal release object patch path,
where Kubernetes would reject immutable `Job.spec.template` updates.

Use `postprocessJob.mode: managed` only when a private environment intentionally
wants the postprocess `Job` owned as a normal Helm release resource. Managed mode
keeps the stable Job object visible after install/upgrade, but pod-template
changes require the environment owner to delete/recreate the Job or use a new
name suffix before upgrading.

## Scheduling

GPU workers, CPU postprocess Jobs, and API-facing pods should use different node
pools. The chart owns worker and postprocess scheduling fields; API scheduling
belongs to the application or platform chart that renders API pods.

Read `docs/scheduling.md` for Karpenter/EKS Auto Mode integration notes and the
GPU/CPU scheduling profiles used by `examples/values-aws-gpu-sqs.yaml`.

## Security

Use workload identity and externally managed secrets for private deployments.
The public examples use placeholder account ids and never include AWS keys,
renderer licenses, customer scenes, or production values.

Read `docs/security.md` for IRSA/EKS Pod Identity guidance, secret handling
boundaries, and the opt-in NetworkPolicy profile in
`examples/values-security-hardening.yaml`.

## Repository Map

```text
charts/render-worker/        Helm chart, templates, values, and schema
examples/                    Public-safe local and AWS-style values files
workers/mock-render-worker/  Local mock worker used by smoke tests
scripts/                     Contract, render, and smoke validation scripts
docs/                        Architecture, scheduling, security, development, roadmap, and evidence map
.github/                     CI workflow and issue/PR templates
VISION.md                    Product direction and safety boundary
```

## Roadmap

Near-term work is intentionally small and GitHub-native:

1. Keep the chart contract covered by local tests and schema validation.
2. Harden public-safe security examples for AWS permissions, secrets, and network boundaries.
3. Expand GPU scheduling examples for worker, CPU, Spot, and post-processing pools.
4. Add optional live-cluster upgrade proof in a private, disposable Kubernetes environment.

See `VISION.md`, `docs/roadmap.md`, and the open GitHub issues for the current queue.

## Contributing

Use the repository workflow for non-trivial changes:

1. Open or link a GitHub issue with scope, acceptance criteria, validation, docs impact, and risk/rollback.
2. Create a topic branch for one coherent change.
3. Open a pull request with local validation evidence.
4. Wait for GitHub Actions.
5. Merge only after the PR is low-risk, green, and reviewable.

Do not batch unrelated chart, example, CI, and documentation changes unless the evidence update depends on all of them.

## Safety Boundary

Allowed in this public repository:

- Helm templates and values schema.
- Placeholder AWS/EKS/SQS/S3 examples.
- Mock queue messages, mock render output, and smoke scripts.
- Documentation for integration seams and security boundaries.

Not allowed:

- real customer assets, scene files, or output frames;
- V-Ray or other renderer binaries, plugins, or license files;
- AWS access keys, account identifiers, real IAM role ARNs, queues, buckets, or ECR paths;
- production deployment automation or live cluster operations;
- sensitive credentials or private configuration values.
