ARG PHP_VER=7.4
FROM php:${PHP_VER}-fpm
LABEL org.opencontainers.image.authors="fabrice.kirchner@casa-due-pur.de"

ARG PHP_VER
RUN apt-get update && apt-get install -y libfcgi-bin libzip-dev zip libicu-dev libxml2-dev libmagickwand-dev --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN apt-get update \
		&& apt-get install -y \
				jpegoptim \
				libonig-dev \
				optipng \
				gifsicle \
				openssl \
				zip \
				unzip \
		&&	pecl install -o -f redis \
		&&	rm -rf /tmp/pear \
		&&	docker-php-ext-enable redis \
		&& docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
		&& docker-php-ext-install -j$(nproc) gd \
		&& docker-php-ext-install -j$(nproc) zip \
		&& docker-php-ext-install mbstring \
		&& docker-php-ext-install gettext \
		&& docker-php-ext-install pdo_mysql \
		&& docker-php-ext-install mysqli \
		&& docker-php-ext-install intl bcmath soap opcache zip pdo \
		&& docker-php-ext-enable mysqli \
		&& pecl install imagick \
		&& docker-php-ext-enable imagick

# Install ioncube
ADD https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz /tmp/
RUN tar xvzfC /tmp/ioncube_loaders_lin_x86-64.tar.gz /tmp/ && \
				php_ext_dir="$(php -i | grep extension_dir | head -n1 | awk '{print $3}')" && \
				mv /tmp/ioncube/ioncube_loader_lin_${PHP_VER}.so "${php_ext_dir}/" && \
		echo "zend_extension = $php_ext_dir/ioncube_loader_lin_${PHP_VER}.so" \
				> /usr/local/etc/php/conf.d/00-ioncube.ini && \
				rm /tmp/ioncube_loaders_lin_x86-64.tar.gz && \
				rm -rf /tmp/ioncube

# composer
RUN curl -S https://getcomposer.org/installer | php \
		&& mv composer.phar /usr/local/bin/composer \
		&& composer self-update

# php.ini
# Increase Upload and Memory Limit
RUN echo "file_uploads = On\n" \
				 "memory_limit = 512M\n" \
				 "upload_max_filesize = 128M\n" \
				 "post_max_size = 128M\n" \
				 "max_execution_time = 600\n" \
				 > /usr/local/etc/php/conf.d/custom-limits.ini
RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
RUN curl --output /usr/local/bin/php-fpm-healthcheck https://www.zyria.de/git/pyrox/php-fpm-healthcheck/raw/branch/master/php-fpm-healthcheck \
	&& chmod +x /usr/local/bin/php-fpm-healthcheck

RUN set -xe && echo "pm.status_path = /status" >> /usr/local/etc/php-fpm.d/zz-docker.conf

HEALTHCHECK --interval=30s --timeout=12s --start-period=30s \
		CMD /usr/local/bin/php-fpm-healthcheck -v
