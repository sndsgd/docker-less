CWD := $(shell pwd)

NODE_VERSION ?= 12.18.4-r0
LESS_VERSION ?= 3.12.2

IMAGE_NAME ?= sndsgd/less
IMAGE := $(IMAGE_NAME):$(LESS_VERSION)

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[33m%s\033[0m~%s\n", $$1, $$2}' \
	| column -s "~" -t

IMAGE_ARGS ?= --quiet
.PHONY: image
image: ## Build the docker image
	@echo "building image..."
	@docker build \
	  $(IMAGE_ARGS) \
		--build-arg NODE_VERSION=$(NODE_VERSION) \
		--build-arg LESS_VERSION=$(LESS_VERSION) \
		--tag $(IMAGE_NAME):latest \
		--tag $(IMAGE) \
		$(CWD)

.PHONY: push
push: ## Push the docker image
push: image
	docker push $(IMAGE)
	docker push $(IMAGE_NAME):latest

.PHONY: run-help
run-help: ## Run `lessc --help`
run-help: image
	@docker run --rm $(IMAGE) --help

.PHONY: run-version
run-version: ## Run `lessc --version`
run-version: image
	@docker run --rm $(IMAGE) --version

.DEFAULT_GOAL := help
