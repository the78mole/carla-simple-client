#!/bin/bash
# Docker build script for x86_64 native Ubuntu 22.04 container
# Usage: ./docker-build.sh [--rebuild]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"
CONTAINER_NAME="carla-x86_64-native"
CONTAINER_TAG="ubuntu-22.04"
FULL_IMAGE_NAME="${CONTAINER_NAME}:${CONTAINER_TAG}"

echo "=== Building CARLA x86_64 Native Container ==="
echo "Repository: $REPO_ROOT"
echo "Container: $FULL_IMAGE_NAME"

# Parse arguments
REBUILD=false
for arg in "$@"; do
    case $arg in
        --rebuild)
            REBUILD=true
            shift
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: $0 [--rebuild]"
            exit 1
            ;;
    esac
done

# Check if image exists and rebuild if requested
if [[ "$REBUILD" == "true" ]]; then
    echo "Rebuilding container from scratch..."
    docker rmi "$FULL_IMAGE_NAME" 2>/dev/null || true
elif docker image inspect "$FULL_IMAGE_NAME" &>/dev/null; then
    echo "Container $FULL_IMAGE_NAME already exists"
    echo "Use --rebuild to force rebuild"
    exit 0
fi

# Build the container
echo "Building container..."
cd "$SCRIPT_DIR"
docker build \
    --tag "$FULL_IMAGE_NAME" \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    --build-arg USER_ID="$(id -u)" \
    --build-arg GROUP_ID="$(id -g)" \
    .

echo "=== Container built successfully ==="
echo "Image: $FULL_IMAGE_NAME"
echo ""
echo "To run the container:"
echo "  docker run -it --rm -v \"$REPO_ROOT:/workspace\" $FULL_IMAGE_NAME"
echo ""
echo "To build examples in container:"
echo "  docker run -it --rm -v \"$REPO_ROOT:/workspace\" $FULL_IMAGE_NAME /workspace/build-containers/x86_64-native-ubuntu-22.04/build-native-examples.sh"