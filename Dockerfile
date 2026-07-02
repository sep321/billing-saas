FROM php:8.2-fpm

# Arguments for configuring a non-root user
ARG USER=laravel
ARG UID=1000
ARG GID=1000

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libpq-dev \
    libzip-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libicu-dev \
    gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo_pgsql \
        pdo_mysql \
        mysqli \
        gd \
        bcmath \
        intl \
        zip \
        opcache \
        pcntl

# Install PHP Redis extension via PECL
RUN pecl install redis \
    && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install NodeSource GPG key and add Node.js 20 repository
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create system user to run Composer and Artisan Commands
RUN groupadd -g ${GID} ${USER} \
    && useradd -u ${UID} -g ${USER} -m -s /bin/bash ${USER} \
    && chown -R ${USER}:${USER} /var/www/html

# Set active user
USER ${USER}

# Expose port 9000 and start php-fpm
EXPOSE 9000
CMD ["php-fpm"]
