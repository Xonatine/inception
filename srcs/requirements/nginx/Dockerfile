FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

RUN adduser -D -g 'www' www

RUN mkdir /www &&\
	chown -R www:www /var/lib/nginx &&\
	chown -R www:www /www

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/script.sh /script.sh
RUN chmod +x /script.sh

ENTRYPOINT ["/usr/local/bin/generate_ssl.sh"]