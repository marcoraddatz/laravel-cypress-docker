#!/bin/bash
set -e

# Load configuration from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "Error: .env file not found!"
    exit 1
fi

# Set image name
FULL_IMAGE_NAME="${DOCKER_HUB_USERNAME:-marcoraddatz}/${REPO_NAME:-laravel-cypress-docker}:${IMAGE_TAG:-latest}"

# Build the image with version arguments
echo "Building $FULL_IMAGE_NAME"
echo "- PHP: $PHP_VERSION"
echo "- Node.js: $NODE_VERSION"

docker build \
  --build-arg PHP_VERSION="$PHP_VERSION" \
  --build-arg NODE_VERSION="$NODE_VERSION" \
  -t "$FULL_IMAGE_NAME" .

# Tag the image for Docker Hub
echo "Tagging image for Docker Hub..."
docker tag "$FULL_IMAGE_NAME" "$FULL_IMAGE_NAME"

# Login to Docker Hub
echo "Logging in to Docker Hub..."
docker login -u "$DOCKER_HUB_USERNAME"

# Push the image to Docker Hub
echo "Pushing $FULL_IMAGE_NAME to Docker Hub..."
docker push "$FULL_IMAGE_NAME"

echo "\nImage successfully pushed to Docker Hub!"
echo "You can now use it with: $FULL_IMAGE_NAME"