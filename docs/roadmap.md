# Roadmap

## Milestone 1: Reusable Helm Component

- Render worker Deployment.
- GPU resource controls.
- KEDA SQS ScaledObject.
- ConfigMap and Secret injection.
- ServiceAccount annotations for AWS permissions.
- Post-processing Job template.
- CI for Helm lint and template rendering.

## Milestone 2: Operational Hardening

- JSON schema for chart values.
- Example IRSA and EKS Pod Identity annotations.
- NetworkPolicy examples.
- PodDisruptionBudget for API-facing components.
- Graceful shutdown notes for interrupted workers.
- CloudWatch and Prometheus label conventions.

## Milestone 3: Portfolio Demo

- Mock render worker image.
- Docker Compose local demo with MinIO and queue substitute.
- Example rendered screenshots.
- End-to-end smoke test plan.
- Resume evidence map with file and command references.

