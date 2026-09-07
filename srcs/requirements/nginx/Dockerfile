FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

RUN usermod -u 33 www-data && groupmod -g 33 www-data

RUN mkdir -p /etc/nginx/ssl

# Se copia como plantilla, no como conf final
COPY conf/nginx.conf.template /etc/nginx/nginx.conf.template
COPY tools/generate_ssl.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/generate_ssl.sh"]