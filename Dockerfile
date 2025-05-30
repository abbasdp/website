FROM php:8.4-fpm

ARG CAPROVER_GIT_COMMIT_SHA=${CAPROVER_GIT_COMMIT_SHA}
ENV CAPROVER_GIT_COMMIT_SHA=${CAPROVER_GIT_COMMIT_SHA}

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    zlib1g-dev libpng-dev libjpeg-dev libfreetype6-dev \
    libxml2-dev \
    libzip-dev \
    libpq-dev \
    libicu-dev \
    vim curl debconf subversion git apt-transport-https apt-utils \
    build-essential locales acl mailutils wget nodejs npm zip unzip \
    gnupg gnupg1 gnupg2 \
    sudo \
    ssh \
    $PHPIZE_DEPS

RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_pgsql pgsql gd opcache zip intl

RUN echo "date.timezone = \"Europe/Berlin\"" > /usr/local/etc/php/conf.d/timezone.ini

COPY --from=composer:2.8 /usr/bin/composer /usr/local/bin/composer

WORKDIR /var/www

COPY . /var/www

RUN composer install --prefer-dist --no-interaction --no-progress --optimize-autoloader

RUN npm i -g yarn

RUN yarn install && yarn build

RUN cp .env.dev .env.local \
    && echo "APP_ENV=prod" >> .env.local \
    && echo "APP_DEBUG=0" >> .env.local

RUN chown -R www-data:www-data /var/www

EXPOSE 80

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN apt-get update && apt-get install -y nginx

RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default

COPY docker/images/nginx/server.conf /etc/nginx/conf.d/default.conf

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]