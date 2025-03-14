CWD := $(shell pwd)

ALPINE_VERSION ?= 3.20
NODE_VERSION ?=
LESS_VERSION ?=
FETCHED_LESS_VERSION ?=

NAME := sndsgd/less
IMAGE_NAME ?= ghcr.io/$(NAME)
LATEST_IMAGE := $(IMAGE_NAME):latest

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[33m%s\033[0m~%s\n", $$1, $$2}' \
	| column -s "~" -t

NODE_VERSION_URL ?= 'https://pkgs.alpinelinux.org/packages?name=nodejs&branch=v$(ALPINE_VERSION)'
NODE_VERSION_PATTERN='(?<=aria-label="Package version">)[^<]+(?=</strong>)'
.PHONY: ensure-node-version
ensure-node-version:
ifeq ($(NODE_VERSION),)
	$(info fetching node package version...)
	$(eval NODE_VERSION = $(shell curl -s $(NODE_VERSION_URL) | grep -Po $(NODE_VERSION_PATTERN) | head -1))
	@echo "found version $(NODE_VERSION)"
endif

VERSION_URL ?= https://www.npmjs.com/package/less
VERSION_PATTERN ?= '(?<="latest":")[^"]+(?=")'
.PHONY: ensure-version
ensure-version:
ifeq ($(LESS_VERSION),)
	@$(info fetching latest version...)
	@$(eval LESS_VERSION = $(shell curl -s $(VERSION_URL) | grep -Po $(VERSION_PATTERN) | head -1))
	@$(eval FETCHED_LESS_VERSION = $(LESS_VERSION))
	@echo "found less version $(LESS_VERSION)"
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
		--tag $(IMAGE) \
		$(CWD)
ifeq ($(LESS_VERSION),$(FETCHED_LESS_VERSION))
	@docker tag $(IMAGE) $(LATEST_IMAGE)
endif

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
ifeq ($(LESS_VERSION),$(FETCHED_LESS_VERSION))
	docker push $(LATEST_IMAGE)
endif

.PHONY: push-cron
push-cron: ## Build and push an image if the version does not exist
push-cron: ensure-node-version ensure-version
	@token_response="$$(curl --silent -f -lSL "https://ghcr.io/token?scope=repository:$(NAME):pull")"; \
	token="$$(echo "$$token_response" | jq -r .token)"; \
	json="$$(curl --silent -f -lSL -H "Authorization: Bearer $$token" https://ghcr.io/v2/$(NAME)/tags/list)"; \
	index="$$(echo "$$json" | jq '.tags | index("$(LESS_VERSION)")')"; \
	if [ "$$index" = "null" ]; then \
		make --no-print-directory push LESS_VERSION=$(LESS_VERSION) NODE_VERSION=$(NODE_VERSION) IMAGE_ARGS=--no-cache; \
	else \
		echo "image for '$(LESS_VERSION)' already exists"; \
	fi

.PHONY: run-help
run-help: ## Run `less --help`
run-help: image
	@docker run --rm $(IMAGE) --help

.DEFAULT_GOAL := help
