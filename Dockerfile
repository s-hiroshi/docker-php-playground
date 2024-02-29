FROM php:latest

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y \
    libzip-dev

COPY ./php.ini /usr/local/etc/php/php.ini
# Install PHP extensions required by Wordpress
RUN docker-php-ext-install \
    zip \
 && pecl install \
    apcu \
 && docker-php-ext-enable \
    apcu
