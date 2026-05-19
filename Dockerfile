FROM webdevops/php-apache:8.3

ENV WEB_DOCUMENT_ROOT=/app
ENV PHP_DISPLAY_ERRORS=1
ENV PHP_MEMORY_LIMIT=512M

WORKDIR /app

# Install system dependencies if needed (October CMS usually needs these)
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libsqlite3-dev \
    libonig-dev \
    && docker-php-ext-install gd zip intl mysqli pdo_mysql opcache mbstring bcmath xml

# Copy composer files
COPY composer.json ./

# Install dependencies
# Note: composer.lock is ignored in your .gitignore, so we don't copy it here
RUN composer install --no-dev --no-interaction --no-scripts --prefer-dist --optimize-autoloader

# Copy the rest of the application
COPY . .

# Fix permissions for October CMS
RUN mkdir -p /app/storage /app/bootstrap/cache /app/themes /app/plugins \
    && chown -R application:application /app \
    && chmod -R 775 /app/storage /app/bootstrap/cache /app/themes /app/plugins

# Ensure index.php is accessible
RUN chmod 644 /app/index.php
