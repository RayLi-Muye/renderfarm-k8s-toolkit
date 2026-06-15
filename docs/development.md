# Development

## Local Checks

Required tools:

- Helm 3

Commands:

```bash
make lint
make template
make template-local
```

## Branching

Use short feature branches:

```text
feature/keda-sqs-scaling
feature/postprocess-job-template
fix/chart-labels
```

## Pull Requests

Every PR should include:

- A narrow summary.
- Acceptance criteria.
- Rendered manifest evidence, when Helm templates changed.
- Security notes when touching Secrets, ServiceAccounts, or IAM-related annotations.

## Issue Workflow

Issues should be small enough to implement and review independently. Prefer one issue per deliverable:

- Chart primitive.
- Example values.
- CI validation.
- Documentation.
- Security hardening.

