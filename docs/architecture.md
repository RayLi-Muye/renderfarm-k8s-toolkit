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

