.PHONY: lint template template-local smoke-local

lint:
	helm lint charts/render-worker

template:
	helm template render-worker charts/render-worker -f examples/values-aws-gpu-sqs.yaml

template-local:
	helm template render-worker charts/render-worker -f examples/values-local.yaml

smoke-local:
	scripts/smoke-local.sh
