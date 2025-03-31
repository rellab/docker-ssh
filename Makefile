# Variables
IMAGE_NAME_BASE := rellab/docker-ssh
DOCKER_REGISTRY := ghcr.io
NOGPU_IMAGE := $(DOCKER_REGISTRY)/$(IMAGE_NAME_BASE)-nogpu:latest
GPU_IMAGE_BASE := $(DOCKER_REGISTRY)/$(IMAGE_NAME_BASE)-gpu
CUDA_VERSIONS := 11.8.0 12.0.0 12.2.0 12.6.2 12.8.1

# GitHub credentials
GITHUB_USER ?=
GITHUB_TOKEN ?=

.PHONY: all build-nogpu build-gpu build login clean

all: build

# No-GPU image (multi-arch)
build-nogpu:
	docker buildx build --platform linux/amd64,linux/arm64 \
		-f Dockerfile-ssh \
		-t $(NOGPU_IMAGE) \
		--push .

# GPU images (amd64 only)
build-gpu:
	@for version in $(CUDA_VERSIONS); do \
	  docker buildx build --platform linux/amd64 \
	    -f Dockerfile-cuda \
	    --build-arg CUDA_VERSION=$$version \
	    -t $(GPU_IMAGE_BASE):$$version \
	    --push .; \
	done

# Both
build: build-nogpu build-gpu

# GHCR login
login:
	@if [ -z "$(GITHUB_USER)" ] || [ -z "$(GITHUB_TOKEN)" ]; then \
	  echo "Error: GITHUB_USER and GITHUB_TOKEN must be set"; \
	  exit 1; \
	fi
	echo "$(GITHUB_TOKEN)" | docker login $(DOCKER_REGISTRY) -u $(GITHUB_USER) --password-stdin

# Clean
clean:
	docker image prune -f
