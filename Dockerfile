ARG PHP_VER=7.4
FROM debian:stable 
LABEL org.opencontainers.image.authors="fabrice.kirchner@casa-due-pur.de"

ARG PHP_VER
RUN apt-get update && apt-get install -y \
			libfcgi-bin \
			zip \
			jpegoptim \
      optipng \
      gifsicle \
      openssl \
      zip \
      unzip \
      curl \
      php-fpm \
			php-redis \
			php-curl\
      php-gd \
			php-zip \
			php-mbstring \
      php-php-gettext \
			php-mysql \
			php-intl \
			php-bcmath \
			php-soap \
			php-opcache \
			php-pdo \
			php-pdo-mysql \
			php-imagick \
		&& rm -rf /var/lib/apt/lists/*

# Install ioncube
ADD https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz /tmp/
RUN tar xvzfC /tmp/ioncube_loaders_lin_x86-64.tar.gz /tmp/ && \
        php_ext_dir="$(php -i | grep extension_dir | head -n1 | awk '{print $3}')" && \
        mv /tmp/ioncube/ioncube_loader_lin_${PHP_VER}.so "${php_ext_dir}/" && \
        rm /tmp/ioncube_loaders_lin_x86-64.tar.gz && \
        rm -rf /tmp/ioncube

# composer
RUN curl -S https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && /usr/local/bin/composer self-update

# php.ini
# Increase Upload and Memory Limit
RUN echo "; configuration for php ZendOpcache module\n; priority=05\nzend_extension = ioncube_loader_lin_${PHP_VER}.so\n" \
         > /etc/php/${PHP_VER}/mods-available/ioncube.ini \
				 && phpenmod ioncube
COPY php.ini /etc/php/${PHP_VER}/fpm/

RUN curl --output /usr/local/bin/php-fpm-healthcheck https://www.zyria.de/git/pyrox/php-fpm-healthcheck/raw/branch/master/php-fpm-healthcheck \
  && chmod +x /usr/local/bin/php-fpm-healthcheck

RUN mkdir /run/php

RUN echo "[docker]\n" \
    "user = www-data\n" \
    "group = www-data\n" \
    "listen = [::]:9000\n" \
    "clear_env = no\n" \
    "pm = dynamic\n" \
    "pm.max_children = 100\n" \
    "pm.start_servers = 20\n" \
    "pm.min_spare_servers = 20\n" \
    "pm.max_spare_servers = 30\n" \
    "pm.max_requests = 2000\n" \
    "php_admin_value[memory_limit] = 1024M\n" \
    "php_admin_value[error_log] = /var/log/fpm-php.log\n" > /etc/php/${PHP_VER}/fpm/pool.d/docker.conf

RUN set -xe && echo "pm.status_path = /status" >> /etc/php/${PHP_VER}/fpm/conf.d/zz-docker.conf 

HEALTHCHECK --interval=30s --timeout=12s --start-period=30s \
   CMD /usr/local/bin/php-fpm-healthcheck -v

EXPOSE 9000
CMD ["php-fpm7.4","--nodaemonize", "--fpm-config", "/etc/php/7.4/fpm/php-fpm.conf"]
