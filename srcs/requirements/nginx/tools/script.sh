#!/bin/ash

mkdir -p /etc/nginx/ssl

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/key.pem \
	-out /etc/nginx/ssl/cert.pem \
	-subj "/CN=$(USER).42.fr"

exec nginx -g "daemon off;"