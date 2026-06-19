# Scheduling

This chart models workload scheduling only. It does not create Kubernetes nodes,
Karpenter `NodePool` objects, EKS Auto Mode node pools, managed node groups, GPU
drivers, or cloud capacity.

The expected integration is:

1. A private infrastructure layer provisions GPU and CPU capacity.
2. That layer labels and taints nodes by workload purpose.
3. This chart selects those nodes with `nodeSelector`, `tolerations`, and
   `affinity`.

## Render Worker GPU Profile

GPU render workers should be isolated onto GPU-capable nodes:

```yaml
gpu:
  enabled: true
  resourceName: nvidia.com/gpu
  count: 1

nodeSelector:
  karpenter.sh/nodepool: render-gpu
  render.node/type: gpu-render

tolerations:
  - key: render.node/type
    operator: Equal
    value: gpu-render
    effect: NoSchedule
  - key: nvidia.com/gpu
    operator: Exists
    effect: NoSchedule
```

The `karpenter.sh/nodepool` label is an example selection key for clusters that
label nodes by Karpenter NodePool. If your EKS Auto Mode or managed node setup
uses different labels, keep the same chart fields and replace the label keys and
values.

## Postprocess CPU Profile

Postprocess jobs usually assemble frames, create manifests, generate previews,
or package outputs. Those tasks are CPU and I/O heavy but normally do not need a
GPU. Schedule them separately so GPU nodes stay available for render workers:

```yaml
postprocessJob:
  enabled: true
  nodeSelector:
    karpenter.sh/nodepool: render-cpu
    render.node/type: cpu-postprocess
  tolerations:
    - key: render.node/type
      operator: Equal
      value: cpu-postprocess
      effect: NoSchedule
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 60
          preference:
            matchExpressions:
              - key: karpenter.sh/capacity-type
                operator: In
                values:
                  - spot
```

The example prefers Spot capacity for interruptible postprocess work. Use
on-demand capacity instead if the job is latency-sensitive or hard to retry.

## API And Submitter Pods

The render API, web UI, submitter, or DCC gateway should not run on GPU nodes.
They do not request `nvidia.com/gpu`, scale on request patterns rather than
frame backlog, and can waste scarce GPU capacity when scheduled onto render
worker nodes.

Keep API-facing pods in a separate CPU profile in the application or platform
chart that owns those pods:

```yaml
nodeSelector:
  render.node/type: platform-api

tolerations:
  - key: render.node/type
    operator: Equal
    value: platform-api
    effect: NoSchedule
```

This repository does not currently render API pods, so API scheduling is
documented as an adjacent integration contract rather than a chart value.

## Karpenter And EKS Auto Mode Boundary

Karpenter and EKS Auto Mode are node scaling integration points, not resources
created by this chart. Keep the node provisioning layer in a private
infrastructure repository or cluster platform module. That layer should decide:

- instance families and GPU types;
- Spot versus on-demand capacity;
- taints and labels applied to GPU, CPU batch, and API pools;
- disruption budgets and consolidation policies;
- IAM, security groups, and node bootstrap configuration.

After that layer labels/taints nodes, use this chart's scheduling fields to
bind worker and postprocess pods to the intended pool.

## Validation

Render and inspect the AWS example:

```bash
helm template render-worker charts/render-worker -f examples/values-aws-gpu-sqs.yaml
```

The rendered manifests should include:

- `nvidia.com/gpu: "1"` on the worker container limits;
- GPU worker `nodeSelector` and tolerations on the worker pod;
- CPU postprocess `nodeSelector`, tolerations, and affinity on the Job pod;
- no Kubernetes node, Karpenter NodePool, EKS Auto Mode, or cloud resource
  objects.

`make test` includes contract checks for the AWS scheduling fields.
