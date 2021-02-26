CWD := $(shell pwd)

ALPINE_VERSION ?= 3.13
NODE_VERSION ?=
LESS_VERSION ?=

IMAGE_NAME ?= sndsgd/less

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[33m%s\033[0m~%s\n", $$1, $$2}' \
	| column -s "~" -t

NODE_VERSION_URL ?= 'https://pkgs.alpinelinux.org/packages?name=nodejs&branch=v$(ALPINE_VERSION)'
NODE_VERSION_PATTERN ?= '(?<=<td class="version">)[^<]+(?=<)'
.PHONY: ensure-node-version
ensure-node-version:
ifeq ($(NODE_VERSION),)
	$(info fetching node package version...)
	$(eval NODE_VERSION = $(shell curl -s $(NODE_VERSION_URL) | grep -Po $(NODE_VERSION_PATTERN) | head -1))
endif

VERSION_URL ?= https://www.npmjs.com/package/less
VERSION_PATTERN ?= '(?<="latest":")[^"]+(?=")'
.PHONY: ensure-version
ensure-version:
ifeq ($(LESS_VERSION),)
	$(info fetching latest version...)
	@$(eval LESS_VERSION = $(shell curl -s $(VERSION_URL) | grep -Po $(VERSION_PATTERN) | head -1))
endif
	@$(eval IMAGE := $(IMAGE_NAME):$(LESS_VERSION))

IMAGE_ARGS ?= --quiet
.PHONY: image
image: ## Build the docker image
image: ensure-node-version ensure-version
	$(info building image for less v$(LESS_VERSION)...)
	@docker build \
	  $(IMAGE_ARGS) \
	  --build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg NODE_VERSION=$(NODE_VERSION) \
		--build-arg LESS_VERSION=$(LESS_VERSION) \
		--tag $(IMAGE_NAME):latest \
		--tag $(IMAGE) \
		$(CWD)

.PHONY: test
test: ## Test the docker image
test: image
	@make --no-print-directory execute-test \
		LESS_VERSION=$(LESS_VERSION) \
		TEST_NAME=one

TEST_ARGS ?=
TEST_INPUT ?= source.less
TEST_NAME ?=
.PHONY: execute-test
execute-test: ensure-version
	$(info testing '$(TEST_NAME)'...)
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
