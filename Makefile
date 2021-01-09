CWD := $(shell pwd)

NODE_VERSION ?= 12.20.1-r0
LESS_VERSION ?=

VERSION_URL ?= https://www.npmjs.com/package/less
VERSION_PATTERN ?= '(?<="latest":")[^"]+(?=")'
ifndef (LESS_VERSION)
	LESS_VERSION = $(shell curl -s $(VERSION_URL) | grep -Po $(VERSION_PATTERN))
endif

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
	@echo "building image for less v$(LESS_VERSION)..."
	@docker build \
	  $(IMAGE_ARGS) \
		--build-arg NODE_VERSION=$(NODE_VERSION) \
		--build-arg LESS_VERSION=$(LESS_VERSION) \
		--tag $(IMAGE_NAME):latest \
		--tag $(IMAGE) \
		$(CWD)

.PHONY: test
test: ## Test the docker image
test: image
	@make --no-print-directory execute-test \
		TEST_NAME=one

TEST_ARGS ?=
TEST_INPUT ?= source.less
TEST_NAME ?=
.PHONY: execute-test
execute-test:
	@echo "testing '$(TEST_NAME)'..."
	@docker run --rm -t \
		-v $(CWD):$(CWD) \
		-w $(CWD) $(IMAGE) \
		$(TEST_ARGS) tests/$(TEST_INPUT) \
		| diff --ignore-trailing-space tests/expect.$(TEST_NAME).css -

.PHONY: push
push: ## Push the docker image
push: test
	docker push $(IMAGE)
	docker push $(IMAGE_NAME):latest

IMAGE_CHECK_URL = https://index.docker.io/v1/repositories/$(IMAGE_NAME)/tags/$(LESS_VERSION)
.PHONY: push-cron
push-cron: ## Build and push an image if the version does not exist
	curl --silent -f -lSL $(IMAGE_CHECK_URL) > /dev/null \
	  || make --no-print-directory push IMAGE_ARGS=--no-cache

.PHONY: run-help
run-help: ## Run `less --help`
run-help: image
	@docker run --rm $(IMAGE) --help

.DEFAULT_GOAL := help
