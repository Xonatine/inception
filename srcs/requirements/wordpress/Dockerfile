FROM debian:bookworm

# Install PHP-FPM and required extensions
RUN apt-get update && apt-get install -y \
  php82 \
  php82-fpm \
  php82-mysql \
  php82-curl \
  php82-gd \
  php82-intl \
  php82-mbstring \
  php82-soap \
  php82-xml \
  php82-zip \
	php82-mysqli \
	php82-json \
	php82-dom \
	php82-exif \
	php82-fileinfo \
	php82-openssl \
	php82-phar \
	php82-iconv \
  wget \
  curl \
  mariadb-client \
	netcat-openbsd \
	ca-certificates \
  && ln -s /usr/sbin/php-fpm8.2 /usr/local/bin/php-fpm \
  && rm -rf /var/lib/apt/lists/*

# Create WordPress directory
WORKDIR /var/www/html

# Copy PHP-FPM configuration (correct version)
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/

# Copy and set permissions for setup script
COPY tools/setup_wordpress.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup_wordpress.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setup_wordpress.sh"]

