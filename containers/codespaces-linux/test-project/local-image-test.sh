#!/bin/bash
set -e
TAG=${1:-dev}
IMAGE_REGISTRY=${2:-mcr.microsoft.com/vscode/devcontainers/universal}
CURRENT_DIRECTORY="$(cd "$(dirname $0)" && pwd)"
docker run -it --rm -v "${CURRENT_DIRECTORY}:/workspace" "${IMAGE_REGISTRY}:${TAG}" sh -c "cd /workspace && ./test.sh false"
