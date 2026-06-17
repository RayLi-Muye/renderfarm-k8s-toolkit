# Roadmap

The roadmap is guided by the product direction and public/private safety boundary in [../VISION.md](../VISION.md).

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

## Delivery Node Format

Each future issue should be small enough to implement as one pull request and should include:

- Goal
- Non-goals
- Expected files changed
- Validation command
- Evidence-map update
- Continuation prompt for the next contributor or agent

The continuation prompt should be executable from a fresh checkout. It should name the issue, the intended files, the validation command, and the docs or evidence updates expected after implementation.
