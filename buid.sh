#!/bin/bash
docker buildx build -t ricariel/php-fpm-ioncube-composer:test --push --platform=linux/amd64,linux/arm64 .
