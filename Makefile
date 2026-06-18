.PHONY: lint template template-local template-minio smoke-local test

lint:
	helm lint charts/render-worker

template:
	helm template render-worker charts/render-worker -f examples/values-aws-gpu-sqs.yaml

template-local:
	helm template render-worker charts/render-worker -f examples/values-local.yaml

template-minio:
	helm template render-worker charts/render-worker -f examples/values-local-minio.yaml

smoke-local:
	scripts/smoke-local.sh

test:
	scripts/chart-contract-tests.sh
