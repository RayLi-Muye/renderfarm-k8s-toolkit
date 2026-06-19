# Architecture

This toolkit focuses on the Kubernetes workload layer of a render farm.

It intentionally does not own:

- VPC and account security design.
- Commercial renderer licensing.
- Customer asset management policy.
- DCC plugin compatibility.
- Final cost model and SLA.

It owns reusable Kubernetes primitives:

- Worker `Deployment` for long-running queue consumers.
- Optional KEDA `ScaledObject` for SQS backlog based scaling.
- GPU resource requests through `nvidia.com/gpu`.
- Node scheduling controls for GPU workers and CPU postprocess jobs.
- ServiceAccount configuration for AWS permissions.
- ConfigMap and Secret injection points.
- Opt-in NetworkPolicy for worker network boundaries.
- Post-processing `Job` template.

## Adapter Seams

The chart exposes provider seams through `adapters.queue`, `adapters.storage`, and `adapters.identity`.

Queue adapters define how workers discover work:

- `mock` renders a local queue placeholder into the worker environment for public smoke paths.
- `sqs` renders an SQS queue URL into the worker environment and drives KEDA SQS trigger metadata.

Storage adapters define how workers discover assets and outputs:

- `local` renders local placeholder paths for mock and reviewer workflows.
- `minio` renders bucket names plus an endpoint for local object-storage-style examples.
- `s3` renders bucket names and region placeholders for AWS/EKS-style deployments.

Identity adapters define how the workload receives credentials or permissions without committing secrets:

- `none` renders no identity integration.
- `irsa` renders a ServiceAccount role annotation from a placeholder role ARN.
- `podIdentity` renders the KEDA `TriggerAuthentication` provider while cluster identity binding stays outside this chart.
- `existingSecret` references an externally managed Kubernetes Secret through `envFrom`.

The adapter values are chart contracts only. They do not create SQS queues, buckets, IAM roles, Secrets, MinIO instances, or cloud resources.

## Design Constraints and Tradeoffs

- The chart treats renderer images as private adapters. Public examples use placeholders because renderer binaries, license files, and customer scenes must stay outside this repository.
- KEDA owns runtime worker replica count when autoscaling is enabled. The chart omits `Deployment.spec.replicas` in that mode so Helm upgrades do not reset an active worker pool.
- KEDA scaler authentication is modeled separately from worker AWS access. The worker ServiceAccount handles job execution permissions; `TriggerAuthentication` handles scaler access to queue metrics.
- GPU render workers, CPU postprocess jobs, and API-facing pods should use separate node pools. API pods are outside this chart and should be scheduled by the application or platform chart that owns them.
- AWS permissions should use workload identity, not committed keys. Renderer licenses and customer credentials should be supplied by private secret management systems, not public values files.
- `worker.env` remains a compatibility overlay and can override adapter-generated environment variables when a private deployment needs a custom contract.
- S3/SQS/EKS names in examples are placeholders. Production infrastructure, IAM policies, and cloud resources are expected to live in private environment repositories.
- Post-processing defaults to Helm hook ownership. Hook mode runs the `Job` on install/upgrade and deletes old hook Jobs before recreating them, avoiding normal Helm patch attempts against immutable Kubernetes `Job.spec.template` fields. `postprocessJob.mode: managed` remains available for private environments that explicitly want a stable release-owned Job and accept delete/recreate responsibility on pod-template changes.

## Workload Flow

```text
1. A render API or DCC submitter writes one message per frame/task.
2. KEDA reads queue backlog and scales worker replicas.
3. Kubernetes schedules worker Pods onto matching GPU nodes.
4. A worker downloads or mounts assets, runs the private renderer, and uploads output.
5. Post-processing Jobs create previews, manifests, archives, or cleanup tasks.
6. Logs and metrics are correlated by job_id, frame_id, pod, and node labels.
```

## Production Integrations

Typical production integrations include:

- Amazon SQS for queueing.
- Amazon S3 for asset staging and output storage.
- Amazon ECR for private worker images.
- Amazon EKS for Kubernetes.
- KEDA for queue-driven scaling.
- Karpenter or EKS Auto Mode for node scaling.
- CloudWatch or Prometheus/Grafana for observability.
- AWS Secrets Manager or External Secrets Operator for sensitive config.

## Public Repository Boundary

The public repository uses placeholders and examples. Real renderer binaries, license files, customer scenes, cloud account ids, and production values belong in private systems.
