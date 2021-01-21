FROM composer:latest AS composer
FROM alpine:3.13
LABEL Maintainer="Diego Tsuyoshi <diego.tsuyoshi@outlook.com>" \
      Description="A lightweight image for laravel development."

COPY --from=composer /usr/bin/composer /usr/bin/composer

# Essentials
RUN apk add --no-cache zip unzip curl nginx supervisor

# Installing PHP
RUN apk add --no-cache php7 \
    php7-common \
    php7-fpm \
    php7-pdo \
    php7-opcache \
    php7-zip \
    php7-phar \
    php7-iconv \
    php7-cli \
    php7-curl \
    php7-openssl \
    php7-mbstring \
    php7-tokenizer \
    php7-fileinfo \
    php7-json \
    php7-xml \
    php7-xmlwriter \
    php7-simplexml \
    php7-dom \
    php7-pdo_mysql \
    php7-pdo_sqlite \
    php7-session \
    php7-tokenizer && \
    rm /etc/nginx/conf.d/default.conf
    # php7-pecl-redis


# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN addgroup -S app && adduser -S app -u 1000 -G app

# Setup document root
RUN mkdir -p /var/www/html


# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R app.app /var/www/ && \
  chown -R app.app /run && \
  chown -R app.app /var/lib/nginx && \
  chown -R app.app /var/log/nginx


# Switch to use a non-root user from here on
USER app

# Add application
WORKDIR /var/www/html
# COPY --chown=app ./src /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 8080
# EXPOSE 6001/tcp

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
