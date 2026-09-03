FROM debian:bookworm

RUN apk add --no-cache\
	php82\
	php82-fpm\
	php82-mysqli\
	php82-json\
	php82-curl\
	php82-dom\
	php82-exif\
	php82-fileinfo\
	php82-mbstring\
	php82-openssl\
	php82-xml\
	php82-zip\
	php82-phar \
	php82-iconv \
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

