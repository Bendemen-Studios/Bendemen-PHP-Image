# Bendemen WordPress Docker images
# Build one PHP version with --build-arg PHP_VERSION=8.3|8.4|8.5.
ARG PHP_VERSION=8.4
FROM ghcr.io/ym0t/pterodactyl-nginx-egg:${PHP_VERSION}-latest

ARG PHP_VERSION=8.4
ENV PHP_VERSION=${PHP_VERSION}
USER root

# Install Redis for the selected PHP version from the same package repositories
# as the upstream image. PECL is not guaranteed to be installed in that image.
RUN set -eux; \
    case "${PHP_VERSION}" in 8.3|8.4|8.5) ;; *) echo "Unsupported PHP_VERSION=${PHP_VERSION}" >&2; exit 1 ;; esac; \
    command -v php${PHP_VERSION}; \
    php${PHP_VERSION} -v; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl php${PHP_VERSION}-redis; \
    php${PHP_VERSION} -r 'if (!extension_loaded("redis")) { fwrite(STDERR, "Redis extension failed to load.\\n"); exit(1); }'; \
    php${PHP_VERSION} -r 'if (!extension_loaded("Zend OPcache")) { fwrite(STDERR, "OPcache is not loaded.\\n"); exit(1); }'; \
    rm -rf /var/lib/apt/lists/*

# Install WP-CLI using the same PHP version as the image.
RUN set -eux; \
    curl -fsSL --retry 3 https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/lib/wp-cli.phar; \
    printf '#!/bin/sh\nexec php%s /usr/local/lib/wp-cli.phar "$@"\n' "${PHP_VERSION}" > /usr/local/bin/wp; \
    chmod 0755 /usr/local/bin/wp; \
    php${PHP_VERSION} /usr/local/lib/wp-cli.phar --info

WORKDIR /home/container
