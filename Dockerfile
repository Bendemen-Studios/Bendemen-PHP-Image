# Custom layer on top of the maintained Pterodactyl Nginx/PHP-FPM image.
# Keeps its Pterodactyl entrypoint, Nginx config, PHP-FPM config and module scripts.
# Build with --build-arg PHP_VERSION=8.3 (or 8.4 / 8.5).
ARG PHP_VERSION=8.4
FROM ghcr.io/ym0t/pterodactyl-nginx-egg:${PHP_VERSION}-latest

ARG PHP_VERSION=8.4
ENV PHP_VERSION=${PHP_VERSION}

USER root

RUN set -eux; \
    case "${PHP_VERSION}" in 8.3|8.4|8.5) ;; *) echo "Unsupported PHP_VERSION=${PHP_VERSION}" >&2; exit 1 ;; esac; \
    apt-get update; \
    apt-get install -y --no-install-recommends "php${PHP_VERSION}-redis"; \
    rm -rf /var/lib/apt/lists/*; \
    php${PHP_VERSION} -r 'if (!extension_loaded("redis")) { fwrite(STDERR, "PHP Redis extension is not loaded in CLI.\n"); exit(1); }'; \
    php${PHP_VERSION} -r 'if (!extension_loaded("Zend OPcache")) { fwrite(STDERR, "PHP OPcache extension is not loaded in CLI.\n"); exit(1); }'

# WP-CLI is available in the image for both the console and startup scripts.
RUN set -eux; \
    curl -fsSL --retry 3 https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/lib/wp-cli.phar; \
    printf '#!/bin/sh\nexec php%s /usr/local/lib/wp-cli.phar "$@"\n' "${PHP_VERSION}" > /usr/local/bin/wp; \
    chmod 0755 /usr/local/bin/wp; \
    php${PHP_VERSION} /usr/local/lib/wp-cli.phar --info

# The upstream image's entrypoint and Pterodactyl startup contract are intentionally retained.
WORKDIR /home/container
