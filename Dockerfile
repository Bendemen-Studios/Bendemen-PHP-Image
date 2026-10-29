# Bendemen WordPress Docker images
# Build one PHP version with --build-arg PHP_VERSION=8.3|8.4|8.5.
ARG PHP_VERSION=8.4
FROM ghcr.io/ym0t/pterodactyl-nginx-egg:${PHP_VERSION}-latest

ARG PHP_VERSION=8.4
ENV PHP_VERSION=${PHP_VERSION}
USER root

# Build a matching Redis extension for the PHP runtime in the upstream image.
RUN set -eux; \
    case "${PHP_VERSION}" in 8.3|8.4|8.5) ;; *) echo "Unsupported PHP_VERSION=${PHP_VERSION}" >&2; exit 1 ;; esac; \
    command -v php${PHP_VERSION}; \
    php${PHP_VERSION} -v; \
    php${PHP_VERSION} -r 'if (!extension_loaded("Zend OPcache")) { fwrite(STDERR, "OPcache is missing in the base image.\n"); exit(1); }'; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl autoconf make gcc g++ pkg-config; \
    pecl_cmd="$(command -v pecl${PHP_VERSION} || command -v pecl || true)"; \
    if [ -z "$pecl_cmd" ]; then echo "PECL is not installed in the upstream image; cannot compile Redis extension." >&2; exit 1; fi; \
    "$pecl_cmd" install redis; \
    rm -rf /var/lib/apt/lists/* /tmp/pear; \
    redis_ini_dir="$(php${PHP_VERSION} -i | sed -n 's/^Scan this dir for additional .ini files => //p' | head -1)"; \
    if [ -z "$redis_ini_dir" ] || [ "$redis_ini_dir" = "(none)" ]; then echo "Cannot determine PHP ini scan directory." >&2; exit 1; fi; \
    mkdir -p "$redis_ini_dir"; \
    printf 'extension=redis.so\n' > "$redis_ini_dir/30-redis.ini"; \
    php${PHP_VERSION} -r 'if (!extension_loaded("redis")) { fwrite(STDERR, "Redis extension failed to load.\n"); exit(1); }'; \
    php${PHP_VERSION} -r 'if (!extension_loaded("Zend OPcache")) { fwrite(STDERR, "OPcache is not loaded.\n"); exit(1); }'

# Install WP-CLI using the same PHP version as the image.
RUN set -eux; \
    curl -fsSL --retry 3 https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/lib/wp-cli.phar; \
    printf '#!/bin/sh\nexec php%s /usr/local/lib/wp-cli.phar "$@"\n' "${PHP_VERSION}" > /usr/local/bin/wp; \
    chmod 0755 /usr/local/bin/wp; \
    php${PHP_VERSION} /usr/local/lib/wp-cli.phar --info

WORKDIR /home/container
