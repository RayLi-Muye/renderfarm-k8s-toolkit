# Evidence Map

This file maps resume claims to public repository evidence.

| Claim | Repository Evidence |
| --- | --- |
| Kubernetes workload orchestration | `charts/render-worker/templates/deployment.yaml` |
| GPU-backed worker scheduling | `gpu.enabled`, `nvidia.com/gpu`, `nodeSelector`, and `tolerations` in chart values |
| Queue-driven scaling | `charts/render-worker/templates/keda-scaledobject.yaml` |
| S3 asset and output workflow | `worker.env.ASSET_BUCKET`, `worker.env.OUTPUT_BUCKET`, and examples |
| Secure AWS access pattern | ServiceAccount annotations for IRSA/EKS Pod Identity |
| Config and secret management | `configmap.yaml`, `secret.yaml`, and values examples |
| Post-render batch processing | `charts/render-worker/templates/postprocess-job.yaml` |
| CI/CD discipline | `.github/workflows/ci.yml` |
| Engineering workflow | issue templates, PR template, roadmap, and GitHub issues |

This repository supports claims about reusable Kubernetes orchestration patterns. It does not prove production scale, customer usage, proprietary renderer setup, or employer-specific implementation details.

