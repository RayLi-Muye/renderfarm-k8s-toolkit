# Vision

`renderfarm-k8s-toolkit` should become a reusable Helm toolkit for orchestrating GPU-backed render workers on Kubernetes and EKS. The project should make the workload contract clear, keep public examples safe to publish, and let maintainers validate the important paths locally before any private renderer, AWS account, or production cluster is involved.

## Product Promise

The toolkit should help a rendering platform team package and review the Kubernetes layer around private render workers:

- define the worker pod contract for queue input, asset access, output upload, logging, and post-processing;
- scale workers from queue backlog through KEDA without Helm fighting runtime autoscaling;
- schedule GPU and non-GPU work onto the right node pools;
- model cloud identity, secrets, and storage integration points without committing private values;
- provide a local mock path that exercises the contract without proprietary renderer binaries.

The public repository should prove orchestration discipline, not production ownership. It should stay renderer-agnostic and avoid claiming that it provisions AWS infrastructure, GPU nodes, object storage, queues, licenses, or customer scenes.

## Target Maintainer Experience

A maintainer should be able to start from a fresh checkout and quickly answer:

- What does the chart render by default?
- Which values are public contracts and which are placeholders?
- How do queue, storage, and identity adapters plug in?
- How are GPU scheduling, KEDA scaling, and post-processing represented?
- Which local checks prove the chart and mock worker still behave as expected?

The preferred feedback loop is local first:

```bash
make lint
make template
make template-local
make smoke-local
scripts/render-examples.sh
```

Cloud-specific behavior belongs in examples and documentation until it can be validated without exposing credentials or production resources.

## Safety Boundary

Public-safe content is allowed:

- Helm templates and values schema.
- Placeholder AWS/EKS/SQS/S3 examples.
- Mock queue messages, mock render output, and smoke scripts.
- Documentation for integration seams and security boundaries.

Private or production content is out of scope:

- renderer binaries, plugins, or license files;
- customer assets, scene files, or output frames;
- real AWS account identifiers, credentials, IAM role ARNs, queues, buckets, or ECR paths;
- production deployment automation, release artifacts, or live cluster operations.

## Near-Term Priorities

1. Strengthen the chart contract with tests and a stricter values schema.
2. Define adapter seams for queue, storage, and identity while preserving the current AWS SQS/S3/IRSA path.
3. Keep the local smoke path useful as the chart contract grows.
4. Add public-safe security examples for AWS permissions, secrets, and network boundaries.
5. Expand GPU scheduling examples for GPU workers, CPU workers, and post-processing jobs.
6. Rework postprocess job upgrade semantics before presenting it as production-ready.

## Non-Goals

This repository should not become a full render manager, DCC integration, cloud provisioning stack, cost model, or production deployment repo. Those concerns should remain in private systems or separate infrastructure projects.
