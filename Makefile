VERSION ?= v4.7.4
.PHONY: help
help: ## Help for usage
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
all: docker

build-minideb: ## Build Wazuh Agent minideb based
	docker build -t mrik974/wazuh-agent:latest .  && \
	docker tag kennyopennix/wazuh-agent:latest kennyopennix/wazuh-agent:$(VERSION)

docker-run: ## Run Wazuh Agent docker image  minideb based
	docker run mrik974/wazuh-agent:$(VERSION)

docker-push-minideb: ## Push Wazuh Agent docker image  minideb based
	docker push mrik974/wazuh-agent:latest && \
	docker push mrik974/wazuh-agent:$(VERSION)

docker-buildx:
	docker buildx build --push -t mrik974/wazuh-agent:$(VERSION) --cache-to type=local,dest=./tmp/ --cache-from type=local,src=./tmp/ .

run-local: ## Run docker compose stack with all agents on board
	docker compose -f tests/single-node/generate-indexer-certs.yml run --rm generator
	docker compose -f docker-compose.yml up -d --build

run-local-minideb: ## Run docker compose stack with only minideb agent.
	docker compose -f tests/single-node/generate-indexer-certs.yml run --rm generator
	AGENT_REPLICAS=0 docker compose -f docker-compose.yml up -d --build

run-local-dev: ## Run Wazuh cluster without agents.
	docker compose -f tests/single-node/generate-indexer-certs.yml run --rm generator
	AGENT_REPLICAS=0 LOCAL_DEV=0 docker compose -f docker-compose.yml up -d --build

destroy: ## Destroy docker compose stack and cleanup
	docker compose down --remove-orphans --rmi local -v
	rm -rf tests/single-node/config/wazuh_indexer_ssl_certs/*
test: ## Run unit tests
	pytest  -v -n auto --capture=sys -x --tb=long
