FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

RUN usermod -u 33 www-data && groupmod -g 33 www-data

RUN mkdir -p /etc/nginx/ssl

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/script.sh /script.sh
RUN chmod +x /script.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/script.sh"]