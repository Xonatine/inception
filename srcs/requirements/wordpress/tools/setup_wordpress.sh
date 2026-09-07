#!/bin/bash
set -e

WP_PATH="/var/www/html"

# --- Leer secretos ---
if [ -n "$WORDPRESS_DB_PASSWORD_FILE" ] && [ -f "$WORDPRESS_DB_PASSWORD_FILE" ]; then
    WORDPRESS_DB_PASSWORD=$(cat "$WORDPRESS_DB_PASSWORD_FILE")
    export WORDPRESS_DB_PASSWORD
fi
if [ -n "$WP_ADMIN_PASSWORD_FILE" ] && [ -f "$WP_ADMIN_PASSWORD_FILE" ]; then
    WP_ADMIN_PASSWORD=$(cat "$WP_ADMIN_PASSWORD_FILE")
fi

echo "Setting up WordPress..."

if [ ! -f "$WP_PATH/wp-config.php" ]; then
    echo "Downloading WordPress..."
    wget -q https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
    tar -xzf /tmp/wordpress.tar.gz -C /tmp
    rm /tmp/wordpress.tar.gz
    cp -rn /tmp/wordpress/* "$WP_PATH" || true
    rm -rf /tmp/wordpress

    WP_SALTS=$(wget -qO- https://api.wordpress.org/secret-key/1.1/salt/)

    cat > "$WP_PATH/wp-config.php" << EOF
<?php
define('DB_NAME', '${WORDPRESS_DB_NAME}');
define('DB_USER', '${WORDPRESS_DB_USER}');
define('DB_PASSWORD', '${WORDPRESS_DB_PASSWORD}');
define('DB_HOST', '${WORDPRESS_DB_HOST}');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

\$table_prefix = '${WORDPRESS_TABLE_PREFIX:-wp_}';

${WP_SALTS}

define('WP_DEBUG', false);

if ( !defined('ABSPATH') )
    define('ABSPATH', __DIR__ . '/');

require_once ABSPATH . 'wp-settings.php';
EOF

    chown -R www-data:www-data "$WP_PATH"

    # --- Esperar a que MariaDB acepte conexiones ---
    echo "Waiting for database..."
    until php -r "new mysqli('${WORDPRESS_DB_HOST}', '${WORDPRESS_DB_USER}', '${WORDPRESS_DB_PASSWORD}', '${WORDPRESS_DB_NAME}');" 2>/dev/null; do
        sleep 1
    done
    echo "Database is ready."

    # --- Instalación automática (sin el asistente web) ---
    su -s /bin/bash www-data -c "wp core install \
        --path='$WP_PATH' \
        --url='https://${DOMAIN_NAME}' \
        --title='Inception' \
        --admin_user='${WP_ADMIN_USER}' \
        --admin_password='${WP_ADMIN_PASSWORD}' \
        --admin_email='${WP_ADMIN_EMAIL}' \
        --skip-email"

    su -s /bin/bash www-data -c "wp user create '${WP_USER}' '${WP_USER_EMAIL}' \
        --role=author \
        --user_pass='${WP_USER_PASSWORD}' \
        --path='$WP_PATH'"

    find "$WP_PATH" -type d -exec chmod 750 {} \;
    find "$WP_PATH" -type f -exec chmod 640 {} \;
    chown -R www-data:www-data "$WP_PATH"

    echo "WordPress setup complete."
else
    echo "WordPress already initialized, skipping setup."
fi

echo "Starting PHP-FPM..."
exec php-fpm8.2 -F
