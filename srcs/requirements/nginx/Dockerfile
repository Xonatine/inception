FROM debian:bookworm

RUN apk update &&\
	apk add --no-cache nginx openssl

RUN adduser -D -g 'www' www

RUN mkdir /www &&\
	chown -R www:www /var/lib/nginx &&\
	chown -R www:www /www

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/script.sh /script.sh
RUN chmod +x /script.sh

ENTRYPOINT ["/usr/local/bin/generate_ssl.sh"]