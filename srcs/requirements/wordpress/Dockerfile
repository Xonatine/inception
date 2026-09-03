FROM debian:bookworm

RUN apt-get update && apt-get install -y\
	php8.2\
	php8.2-fpm\
	php8.2-mysqli\
	php8.2-json\
	php8.2-curl\
	php8.2-dom\
	php8.2-exif\
	php8.2-fileinfo\
	php8.2-mbstring\
	php8.2-openssl\
	php8.2-xml\
	php8.2-zip\
	php8.2-phar \
	php8.2-iconv \
	curl \
	wget \
	mariadb-client \
	netcat-openbsd \
	ca-certificates

RUN adduser -S www-data -G www-data || true
RUN mkdir -p /var/www/wordpress /run/php && \
    chown -R www-data:www-data /var/www/wordpress /run/php

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp
RUN ln -s /usr/bin/php82 /usr/local/bin/php

COPY ./conf/www.conf /etc/php82/php-fpm.d/www.conf
COPY ./tools/script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh

WORKDIR /var/www/wordpress

EXPOSE 9000


ENTRYPOINT ["/usr/local/bin/setup_wordpress.sh"]

