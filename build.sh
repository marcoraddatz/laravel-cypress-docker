#!/bin/bash
set -e

# Load configuration from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "Error: .env file not found!"
    exit 1
fi

DOCKER_HUB_USERNAME="${DOCKER_HUB_USERNAME:-marcoraddatz}"
REPO_NAME="${REPO_NAME:-laravel-cypress-docker}"

# Create version-specific tag with minor versions (e.g., php-8.3-node-22.17)
VERSION_TAG="php-${PHP_VERSION}-node-${NODE_VERSION}"
SHORT_TAG="php${PHP_VERSION}-node$(echo $NODE_VERSION | cut -d. -f1)"

# Set image names
LATEST_IMAGE_NAME="$DOCKER_HUB_USERNAME/$REPO_NAME:latest"
VERSIONED_IMAGE_NAME="$DOCKER_HUB_USERNAME/$REPO_NAME:$VERSION_TAG"
SHORT_TAG_IMAGE_NAME="$DOCKER_HUB_USERNAME/$REPO_NAME:$SHORT_TAG"

# Build the image with version arguments
echo "Building images with:"
echo "- PHP: $PHP_VERSION"
echo "- Node.js: $NODE_VERSION"

# Ensure Docker Buildx is available
if ! docker buildx version &> /dev/null; then
    echo "Error: Docker Buildx is required but not installed or not enabled."
    echo "Please enable Docker Buildx and try again."
    exit 1
fi

# Create and use a builder instance that supports multi-architecture builds
echo "Setting up Docker Buildx..."
docker buildx create --name mybuilder --use --bootstrap > /dev/null 2>&1 || true

# Login to Docker Hub if credentials are provided
if [ -n "$DOCKER_HUB_TOKEN" ]; then
    echo "Logging in to Docker Hub..."
    echo "$DOCKER_HUB_TOKEN" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin
fi

# Build for both AMD64 and ARM64
echo "Building multi-architecture images..."
echo "- Tag: latest (${LATEST_IMAGE_NAME})"
echo "- Tag: ${VERSION_TAG} (${VERSIONED_IMAGE_NAME})"
echo "- Tag: ${SHORT_TAG} (${SHORT_TAG_IMAGE_NAME})"

docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg PHP_VERSION="$PHP_VERSION" \
  --build-arg NODE_VERSION="$NODE_VERSION" \
  -t "$LATEST_IMAGE_NAME" \
  -t "$VERSIONED_IMAGE_NAME" \
  -t "$SHORT_TAG_IMAGE_NAME" \
  --push \
  .

echo "\n✅ Successfully built and pushed multi-architecture images to Docker Hub!"
echo "📦 Images:"
echo "  - $LATEST_IMAGE_NAME (latest)"
echo "  - $VERSIONED_IMAGE_NAME (full version)"
echo "  - $SHORT_TAG_IMAGE_NAME (short version)"
echo "📌 Platforms for each tag:"
echo "  - linux/amd64 (GitHub Actions runners)"
echo "  - linux/arm64 (Apple Silicon/M1/M2)"