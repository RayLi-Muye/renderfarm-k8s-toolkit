# Evidence Map

This file maps resume claims to public repository evidence.

| Claim | Evidence | How to Verify | Status | Boundary |
| --- | --- | --- | --- | --- |
| Kubernetes workload orchestration | `charts/render-worker/templates/deployment.yaml` | `make template` and inspect rendered worker `Deployment` | Implemented | Does not run a real renderer by default |
| GPU-backed worker scheduling | `charts/render-worker/templates/deployment.yaml`, `examples/values-aws-gpu-sqs.yaml` | Render the AWS example and inspect `nvidia.com/gpu`, `nodeSelector`, and `tolerations` | Implemented | Does not provision GPU nodes |
| Queue-driven scaling | `charts/render-worker/templates/keda-scaledobject.yaml` | Render the AWS example and inspect the KEDA `ScaledObject` | Implemented | No live AWS SQS queue is created |
| KEDA scaler authentication | `charts/render-worker/templates/keda-triggerauthentication.yaml`, `examples/values-aws-gpu-sqs.yaml` | Render the AWS example and inspect `TriggerAuthentication` plus `authenticationRef` | Implemented | Cluster-level KEDA operator identity is configured outside this chart |
| S3 asset and output workflow | `worker.env.ASSET_BUCKET`, `worker.env.OUTPUT_BUCKET`, `examples/values-aws-gpu-sqs.yaml` | Render examples and inspect worker environment variables | Implemented | No bucket or object storage is created |
| Secure AWS access pattern | `charts/render-worker/templates/serviceaccount.yaml`, `charts/render-worker/templates/keda-triggerauthentication.yaml` | Inspect ServiceAccount annotations and KEDA pod identity settings | Started | Least-privilege IAM policies remain environment-specific |
| Config and secret management | `charts/render-worker/templates/configmap.yaml`, `charts/render-worker/templates/secret.yaml` | Render values with string-like and numeric values; output remains string typed | Implemented | Secrets are injection points, not a production secret manager |
| Post-render batch processing | `charts/render-worker/templates/postprocess-job.yaml` | Render local or AWS examples and inspect the `Job` | Implemented | Upgrade semantics need hardening before production use |
| Public mock worker smoke path | `workers/mock-render-worker/mock-render-worker.sh`, `scripts/smoke-local.sh`, `examples/mock-queue.txt` | Run `make smoke-local` and inspect placeholder frame output plus the postprocess manifest | Implemented | Mock path validates the public worker contract only; it is not a real renderer, queue service, object store, or cluster test |
| CI/CD discipline | `.github/workflows/ci.yml` | Review GitHub Actions runs; CI executes Helm lint, template rendering, and kubeconform validation | Implemented | Static schema validation only; no live cluster, admission webhook, KEDA operator, AWS SQS, or GPU node behavior is exercised |
| Tool install integrity | `.github/workflows/ci.yml` | Inspect CI install steps for Helm and kubeconform checksum verification | Implemented | Checksums verify downloaded release assets, not upstream maintainer identity |
| Engineering workflow | `.github/ISSUE_TEMPLATE/*`, `.github/pull_request_template.md`, `docs/roadmap.md` | Review merged PRs and open delivery issues | Active | Solo project, but PR discipline is preserved |

This repository supports claims about reusable Kubernetes orchestration patterns. It does not prove production scale, customer usage, proprietary renderer setup, or employer-specific implementation details.

## Reviewer Notes

- The public chart is intentionally renderer-agnostic. Private V-Ray worker images, licenses, assets, and customer values are out of scope.
- The mock worker is a public-safe contract test and does not contain renderer binaries, licenses, customer scenes, or cloud credentials.
- AWS examples use placeholder account IDs and resource names.
- Claims should be read as evidence of orchestration, packaging, and review discipline, not as proof of a deployed customer environment.
