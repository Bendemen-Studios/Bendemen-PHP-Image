#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: GHCR_USER=your-github-username ./build-push.sh
: "${GHCR_USER:?Set GHCR_USER to your lowercase GitHub username/org}"
IMAGE="ghcr.io/${GHCR_USER,,}/bendemen-wordpress"

# Set PLATFORMS=linux/amd64 to build only for one node if desired.
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"

# Requires Docker Buildx and an authenticated GHCR session (docker login ghcr.io).
for version in 8.3 8.4 8.5; do
  echo "==> Building and pushing ${IMAGE}:${version}-latest for ${PLATFORMS}"
  docker buildx build \
    --pull \
    --platform "${PLATFORMS}" \
    --build-arg PHP_VERSION="${version}" \
    --tag "${IMAGE}:${version}-latest" \
    --push \
    .
done

echo "Published images to ${IMAGE}:{8.3,8.4,8.5}-latest"
echo "Import egg-wordpress.json after replacing YOUR_GITHUB_USERNAME in docker_images."
