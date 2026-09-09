#!/bin/bash
set -e

mkdir -p /etc/nginx/ssl

: "${DOMAIN_NAME:=localhost}"

if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    echo "Generating self-signed SSL certificate for ${DOMAIN_NAME}..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=${DOMAIN_NAME}"
    chmod 600 /etc/nginx/ssl/nginx.key
    chmod 644 /etc/nginx/ssl/nginx.crt
else
    echo "SSL certificate already exists. Skipping generation."
fi

# --- Sustituir ${DOMAIN_NAME} en la plantilla antes de arrancar ---
envsubst '${DOMAIN_NAME}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "Testing nginx configuration..."
nginx -t
echo "Nginx configuration test passed."

echo "Starting Nginx..."
exec nginx -g "daemon off;"