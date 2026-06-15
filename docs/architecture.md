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
- Node scheduling controls for GPU and non-GPU workloads.
- ServiceAccount configuration for AWS permissions.
- ConfigMap and Secret injection points.
- Post-processing `Job` template.

## Design Constraints and Tradeoffs

- The chart treats renderer images as private adapters. Public examples use placeholders because renderer binaries, license files, and customer scenes must stay outside this repository.
- KEDA owns runtime worker replica count when autoscaling is enabled. The chart omits `Deployment.spec.replicas` in that mode so Helm upgrades do not reset an active worker pool.
- KEDA scaler authentication is modeled separately from worker AWS access. The worker ServiceAccount handles job execution permissions; `TriggerAuthentication` handles scaler access to queue metrics.
- S3/SQS/EKS names in examples are placeholders. Production infrastructure, IAM policies, and cloud resources are expected to live in private environment repositories.
- Post-processing is currently represented as a chart-rendered `Job`; its production upgrade semantics are tracked separately because Kubernetes Job pod templates are immutable after creation.

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
