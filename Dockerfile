FROM php:latest

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y \
    libzip-dev \
    libmemcached-dev \
    zlib1g-dev \
    libssl-dev

COPY ./php.ini /usr/local/etc/php/php.ini
RUN docker-php-ext-install \
    zip \
 && pecl install \
    memcached \
 && docker-php-ext-enable \
    memcached
