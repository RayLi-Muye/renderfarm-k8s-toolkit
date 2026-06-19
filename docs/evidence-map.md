# Evidence Map

This file maps resume claims to public repository evidence.

| Claim | Evidence | How to Verify | Status | Boundary |
| --- | --- | --- | --- | --- |
| Kubernetes workload orchestration | `charts/render-worker/templates/deployment.yaml` | `make template` and inspect rendered worker `Deployment` | Implemented | Does not run a real renderer by default |
| GPU-backed worker scheduling | `charts/render-worker/templates/deployment.yaml`, `examples/values-aws-gpu-sqs.yaml`, `docs/scheduling.md` | Render the AWS example or run `make test`; inspect `nvidia.com/gpu`, GPU worker `nodeSelector`, and worker tolerations | Implemented | Does not provision GPU nodes, Karpenter NodePools, EKS Auto Mode pools, or managed node groups |
| CPU postprocess scheduling | `charts/render-worker/templates/postprocess-job.yaml`, `examples/values-aws-gpu-sqs.yaml`, `docs/scheduling.md` | Render the AWS example or run `make test`; inspect the postprocess Job `nodeSelector`, tolerations, and affinity | Implemented | Does not create CPU nodes or run a live postprocess job |
| Queue-driven scaling | `charts/render-worker/templates/keda-scaledobject.yaml` | Render the AWS example and inspect the KEDA `ScaledObject` | Implemented | No live AWS SQS queue is created |
| KEDA scaler authentication | `charts/render-worker/templates/keda-triggerauthentication.yaml`, `examples/values-aws-gpu-sqs.yaml` | Render the AWS example and inspect `TriggerAuthentication` plus `authenticationRef` | Implemented | Cluster-level KEDA operator identity is configured outside this chart |
| S3 asset and output workflow | `worker.env.ASSET_BUCKET`, `worker.env.OUTPUT_BUCKET`, `examples/values-aws-gpu-sqs.yaml` | Render examples and inspect worker environment variables | Implemented | No bucket or object storage is created |
| Queue, storage, and identity adapter seams | `charts/render-worker/values.yaml`, `charts/render-worker/templates/_helpers.tpl`, `examples/values-local.yaml`, `examples/values-local-minio.yaml`, `examples/values-aws-gpu-sqs.yaml` | Run `make test`; inspect adapter-generated worker env, KEDA SQS metadata, ServiceAccount annotations, podIdentity provider rendering, and existingSecret envFrom | Implemented | Adapter values are chart contracts only; they do not create queues, buckets, IAM roles, Secrets, MinIO, or AWS resources |
| Secure AWS access pattern | `charts/render-worker/templates/serviceaccount.yaml`, `charts/render-worker/templates/keda-triggerauthentication.yaml` | Inspect ServiceAccount annotations and KEDA pod identity settings | Started | Least-privilege IAM policies remain environment-specific |
| Config and secret management | `charts/render-worker/templates/configmap.yaml`, `charts/render-worker/templates/secret.yaml` | Render values with string-like and numeric values; output remains string typed | Implemented | Secrets are injection points, not a production secret manager |
| Post-render batch processing | `charts/render-worker/templates/postprocess-job.yaml` | Render local or AWS examples and inspect the `Job` | Implemented | Upgrade semantics need hardening before production use |
| Public mock worker smoke path | `workers/mock-render-worker/mock-render-worker.sh`, `scripts/smoke-local.sh`, `examples/mock-queue.txt` | Run `make smoke-local` and inspect placeholder frame output plus the postprocess manifest | Implemented | Mock path validates the public worker contract only; it is not a real renderer, queue service, object store, or cluster test |
| Chart contract tests and values schema | `scripts/chart-contract-tests.sh`, `charts/render-worker/values.schema.json` | Run `make test`; CI also runs these tests on PRs and `main` pushes | Implemented | Contract tests inspect rendered manifests and schema failures only; no live Kubernetes, KEDA operator, AWS SQS, MinIO, or GPU node behavior is exercised |
| CI/CD discipline | `.github/workflows/ci.yml` | Review GitHub Actions runs; CI executes Helm lint, template rendering, kubeconform validation, mock smoke, and chart contract tests | Implemented | Static and local validation only; no live cluster, admission webhook, KEDA operator, AWS SQS, MinIO, or GPU node behavior is exercised |
| Tool install integrity | `.github/workflows/ci.yml` | Inspect CI install steps for Helm and kubeconform checksum verification | Implemented | Checksums verify downloaded release assets, not upstream maintainer identity |
| Engineering workflow | `.github/ISSUE_TEMPLATE/*`, `.github/pull_request_template.md`, `docs/roadmap.md` | Review merged PRs and open delivery issues | Active | Solo project, but PR discipline is preserved |

This repository supports claims about reusable Kubernetes orchestration patterns. It does not prove production scale, customer usage, proprietary renderer setup, or employer-specific implementation details.

## Reviewer Notes

- The public chart is intentionally renderer-agnostic. Private V-Ray worker images, licenses, assets, and customer values are out of scope.
- The mock worker is a public-safe contract test and does not contain renderer binaries, licenses, customer scenes, or cloud credentials.
- AWS examples use placeholder account IDs and resource names.
- Scheduling examples use placeholder labels and taints. Private cluster infrastructure owns the actual Karpenter, EKS Auto Mode, or managed node group configuration.
- Claims should be read as evidence of orchestration, packaging, and review discipline, not as proof of a deployed customer environment.
