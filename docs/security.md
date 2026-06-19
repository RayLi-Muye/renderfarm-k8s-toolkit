# Security Hardening

This repository contains public-safe chart contracts and examples only. It does
not contain AWS credentials, renderer licenses, customer scene files, production
bucket names, production queue names, or private account identifiers.

## AWS Permissions

Do not commit AWS access keys, static session tokens, or `.env` files. Render
workers should receive AWS permissions through the Kubernetes ServiceAccount
identity path used by the cluster:

- **IRSA**: annotate the worker ServiceAccount with a role ARN. The public
  examples use placeholder account ids and role names.
- **EKS Pod Identity**: bind the ServiceAccount to a role outside this chart and
  configure KEDA's `TriggerAuthentication` provider.
- **Existing Secret**: use only for local/private integrations where a secret is
  created by an external controller. Do not publish the secret contents.

The chart can render a ServiceAccount annotation for IRSA:

```yaml
adapters:
  identity:
    type: irsa
    irsa:
      annotationKey: eks.amazonaws.com/role-arn
      roleArn: arn:aws:iam::000000000000:role/render-worker-irsa
```

The IAM role and policy are owned by private infrastructure. A typical
least-privilege policy should be scoped to the exact queue, buckets, KMS keys,
and logs used by the environment. Keep the actual policy document in the private
infrastructure repository, not in public example values.

## Secret Handling

Do not put these values in `worker.env`, `secret.stringData`, examples, issues,
PR descriptions, or logs:

- AWS access keys or session tokens;
- V-Ray, Arnold, RenderMan, Blender add-on, or DCC license files;
- customer scenes, paths, frame output, or asset URLs;
- production queue URLs, bucket names, ECR repositories, or account ids.

Use one of these private patterns instead:

- AWS Secrets Manager plus External Secrets Operator;
- another cluster-approved external secret controller;
- sealed/encrypted secrets stored in a private repo;
- short-lived identity from IRSA or EKS Pod Identity whenever possible.

`secret.create` is intentionally `false` in the security example. If a private
deployment needs a Kubernetes Secret, create it outside this public chart and
reference it with the `existingSecret` identity adapter.

## Network Boundary

Render workers are queue consumers. They normally do not need inbound traffic
from API pods, submitters, CI jobs, or unrelated workloads. Enable
`networkPolicy` when the target cluster enforces Kubernetes NetworkPolicy:

```yaml
networkPolicy:
  enabled: true
  policyTypes:
    - Ingress
    - Egress
  ingress: []
  egress:
    - to:
        - podSelector:
            matchLabels:
              renderfarm.dev/network-role: aws-egress-gateway
      ports:
        - protocol: TCP
          port: 443
```

The example in `examples/values-security-hardening.yaml` also allows DNS egress.
Adapt labels and egress paths for the private cluster. Kubernetes NetworkPolicy
does not create VPC endpoints, security groups, NAT gateways, or firewall rules.

## Public Example Boundary

`examples/values-security-hardening.yaml` demonstrates:

- ServiceAccount annotation shape with placeholder IRSA role ARN;
- no direct AWS key injection;
- no renderer license or customer secret material;
- opt-in NetworkPolicy that selects only worker pods;
- egress through DNS and a placeholder private AWS egress gateway.

It is a review artifact, not a production values file. Private environments must
replace placeholder names, own IAM and secret manager resources, and validate the
network policy against their cluster CNI and egress design.
