.PHONY: check-pod

PHP_VERSION ?= 8.2
POSTGRES_PASSWORD ?= !ChangeMe!
WEB_PORT ?= 8080

# Build an FPM image for dev
build-php-fpm:
	podman build --tag php-fpm:${PHP_VERSION} --build-arg PHP_VERSION=${PHP_VERSION} --target dev -f container/php/Containerfile .
 
# build a tools container with composer
build-php-tools:
	podman build --tag php-tools:${PHP_VERSION} --build-arg PHP_VERSION=${PHP_VERSION} --target tools -f container/php/Containerfile .

build: build-php-tools build-php-fpm

start-fpm: check-pod
	podman run -dt --replace \
	--name $(shell basename $(CURDIR))-fpm \
	--pod $(shell basename $(CURDIR)) \
	-w /code \
	-v $(CURDIR)/:/code \
	-v $(CURDIR)/container/php/xdebug.ini:/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
	-v $(CURDIR)/container/php/error_reporting.ini:/usr/local/etc/php/conf.d/error_reporting.ini \
	-e PHP_IDE_CONFIG="serverName=localhost" \
	php-fpm:${PHP_VERSION}

stop-fpm:
	podman container rm -fv $(shell basename $(CURDIR))-fpm

start-nginx: check-pod
	podman run -dt --replace \
	--name $(shell basename $(CURDIR))-nginx  \
	--pod $(shell basename $(CURDIR)) \
	-v $(CURDIR)/container/nginx/default.conf:/etc/nginx/conf.d/default.conf \
	-v $(CURDIR)/:/code \
	-e PHP_IDE_CONFIG="serverName=localhost" \
	nginx:alpine

stop-nginx:
	podman container rm -fv $(shell basename $(CURDIR))-nginx

start-pg: check-pod
	@if ! podman volume exists pg-data; then \
		echo "Volume pg-data not exists... creating..."; \
		podman volume create pg-data; \
	fi

	podman run -dt --replace \
	--name $(shell basename $(CURDIR))-pg \
	--pod $(shell basename $(CURDIR)) \
	-v pg-data:/var/lib/postgresql/data \
	-e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
	-e POSTGRES_USER=symfony \
    -e POSTGRES_DB=public \
    -e LANG=de_DE.utf8 \
	-e POSTGRES_INITDB_ARGS='--locale-provider=icu --icu-locale=de-DE' \
    --env-file=$(CURDIR)/container/database/.env \
	postgres:15-alpine3.18

stop-pg:
	podman container rm -fv $(shell basename $(CURDIR))-pg

rem-pg-data:
	podman volume rm -f pg-data

start: check-pod build start-pg start-fpm start-nginx

stop: stop-fpm stop-nginx stop-pg stop-pod

check-pod:
	@if ! podman pod exists $(shell basename $(CURDIR)); then \
		echo "Pod is not running. Starting the pod..."; \
		podman pod create -p "${WEB_PORT}:80" --name $(shell basename $(CURDIR)); \
	else \
		echo "Pod $(shell basename $(CURDIR)) is already running."; \
	fi

start-pod: check-pod

stop-pod:
	podman pod rm -f $(shell basename $(CURDIR))
