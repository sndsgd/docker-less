CWD := $(shell pwd)

NODE_VERSION ?= 12.17.0-r0
LESS_VERSION ?= 3.11.3

IMAGE_NAME ?= sndsgd/less
IMAGE := $(IMAGE_NAME):$(LESS_VERSION)

.PHONY: build-image
build-image:
	docker build \
		--build-arg NODE_VERSION=$(NODE_VERSION) \
		--build-arg LESS_VERSION=$(LESS_VERSION) \
		--tag $(IMAGE_NAME):latest \
		--tag $(IMAGE) \
		$(CWD)

.PHONY: build
build: build-image
	docker push $(IMAGE)
	docker push $(IMAGE_NAME):latest

.PHONY: help
help: build-image
	docker run --rm $(IMAGE) --help
