# Bendemen WordPress custom Docker images for Pterodactyl

This package builds **custom derived images** for PHP 8.3, 8.4 and 8.5. They inherit the upstream `ghcr.io/ym0t/pterodactyl-nginx-egg` image, preserving its Nginx, PHP-FPM, Pterodactyl entrypoint and `start-modules.sh` contract, and add:

- the version-matched `phpX.Y-redis` extension;
- a global `wp` command backed by WP-CLI;
- build-time checks that Redis and OPcache load in PHP CLI.

This is not a fully independent rewrite of Nginx/PHP-FPM. It intentionally builds on the upstream image so its Pterodactyl startup behavior stays compatible.

## Build and publish

Requirements: Docker with Buildx, a GitHub account, a GitHub Container Registry package namespace, and a Personal Access Token with `write:packages` (plus `read:packages` if your account/package setup requires it).

1. Create a GitHub repository for this folder and push these files.
2. In GitHub, create a classic Personal Access Token with `write:packages`.
3. Log in to GHCR from the machine where you build:

   ```bash
   echo 'YOUR_GITHUB_TOKEN' | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
   ```

4. Build and publish all three images (use your lowercase GitHub username or organization):

   ```bash
   GHCR_USER=your-github-username ./build-push.sh
   ```

The script builds `linux/amd64` and `linux/arm64` multi-architecture images. If you only need the node's architecture, remove `--platform linux/amd64,linux/arm64` from the script or build one version manually:

```bash
docker build --pull --build-arg PHP_VERSION=8.4 \
  -t ghcr.io/YOUR_GITHUB_USERNAME/bendemen-wordpress:8.4-latest .
docker push ghcr.io/YOUR_GITHUB_USERNAME/bendemen-wordpress:8.4-latest
```

Repeat for `8.3` and `8.5`.

## Import the Egg

1. Open `egg-wordpress.json` and replace `YOUR_GITHUB_USERNAME` in all three `docker_images` values with your lowercase GitHub username/org.
2. Import the JSON into Pterodactyl.
3. Select the matching custom image for the server's PHP version. The `PHP_VERSION` Egg variable must match the selected image.
4. Test with a non-production WordPress server first.

## Included runtime

The inherited image supplies Nginx, PHP-FPM, its existing Pterodactyl entrypoint/start scripts, and OPcache support. The custom layer installs the matching Redis PHP extension and WP-CLI. Redis itself is an external service; these images do **not** run a Redis server.

The Egg's WordPress installer still downloads WordPress and its installation-time dependencies. This Docker build only puts the runtime tools/extensions into the image.

## Important notes

- The images are not published by this package. You must build and push them to your own GHCR namespace before selecting them in Pterodactyl.
- This package was source-checked, but Docker builds were not run in this environment. A package or upstream image change can cause a build to fail; the build is designed to fail rather than silently ship without Redis/OPcache.
- Pin immutable tags/digests for production once you settle on a tested build. `*-latest` tags are convenient for initial setup but can change.
- Keep NPM API credentials in administrator-only variables. Hidden Egg variables are not a replacement for access control for panel administrators or container files.
- PHP 8.3 is in security-fixes-only maintenance according to the upstream image project; use a supported version for new sites when plugin compatibility permits.
