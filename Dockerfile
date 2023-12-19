FROM php:8.1.26

EXPOSE 8080

COPY ./php.ini /usr/local/etc/php/conf.d/php.ini

RUN mkdir /var/log/php

RUN mkdir -p /var/www/html
WORKDIR /var/www/html

# Install Debian packagies
# PHP extension zip requires zlib1g-dev
# PHP extension imagick requires pkg-config, libmagickwand-dev
# WordPress Unit Test requires subversion subversion-tools
RUN apt-get update \
 && apt-get install -y \
    git \
    libmemcached-dev \
    libmagickwand-dev \
    libssl-dev \
    libzip-dev \
    default-mysql-client \
    pkg-config \
    subversion \
    subversion-tools \
    unzip \
    wget \
    zip \
    zlib1g-dev

# Install PHP extensions required by Wordpress
RUN docker-php-ext-install \
    exif \
    intl \
    mysqli \
    zip \
 && pecl install \
    apcu \
    igbinary \ 
    imagick \
    memcached \
 && docker-php-ext-enable \
    apcu \
    igbinary \
    imagick \
    memcached

# Install WodrPress Core
RUN wget -q https://ja.wordpress.org/latest-ja.zip -P /var/www/html
RUN unzip -q /var/www/html/latest-ja.zip && rm -f /var/www/html/latest-ja.zip
RUN mv -f /var/www/html/wordpress /var/www/html/wp 

# Install WP-CLI
# @see https://wp-cli.org/
RUN wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /var/www/html \
 && chmod u+x /var/www/html/wp-cli.phar \
 && mv -f /var/www/html/wp-cli.phar /usr/local/bin/wp

# Copy wp-config.php
COPY ./wp-config.php /var/www/html/wp/wp-config.php

# Install Composer for PHPUnit
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
 && php -r "if (hash_file('sha384', 'composer-setup.php') === 'e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
 && php composer-setup.php \
 && php -r "unlink('composer-setup.php');" \
 && chmod u+x composer.phar \
 && mv composer.phar /usr/local/bin/composer

# Install PHPUnit & PHPUnit Polyfills 
COPY ./composer.json /var/www/html/wp/composer.json
RUN cd wp \
 && env COMPOSER_ALLOW_SUPERUSER=1 composer install \
 && composer dump-autoload 

# Set up mailhog
RUN curl -sSLO https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64 \
    && chmod +x mhsendmail_linux_amd64 \
    && mv mhsendmail_linux_amd64 /usr/local/bin/mhsendmail \
    && echo 'sendmail_path = "/usr/local/bin/mhsendmail --smtp-addr=mailhog:1025"' > /usr/local/etc/php/conf.d/sendmail.ini

RUN rm -rf /var/www/html/wp/wp-content
RUN ln -s /var/www/html/wp-content /var/www/html/wp/wp-content

CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/html/wp"]
