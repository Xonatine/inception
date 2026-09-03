#!/bin/ash
set -e

SQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_PASSWORD=$(cat /run/secrets/wp_password)
WP="php -d memory_limit=512M /usr/local/bin/wp"

echo "Esperando a MariaDB..."
while ! ping -c 1 mariadb > /dev/null 2>&1; do
    echo "DNS mariadb no resuelto todavía..."
    sleep 2
done

while ! nc -z mariadb 3306; do
    echo "Puerto 3306 de mariadb no responde..."
    sleep 2
done
echo "MariaDB lista y visible."

cd /var/www/wordpress

export PHP_OPTIONS="-d memory_limit=512M"

echo "Descargando WordPress..."
$WP core download --allow-root || echo "WordPress ya está descargado."

echo "Creando wp-config.php..."
$WP config create \
    --dbname="$SQL_DATABASE" \
    --dbuser="$SQL_USER" \
    --dbpass="$SQL_PASSWORD" \
    --dbhost="mariadb" \
    --force \
    --allow-root

echo "Instalando WordPress..."
$WP core install \
    --url="https://$(USER).42.fr" \
    --title="Inception" \
    --admin_user="$(USER)" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$(USER)@student.42madrid.com" \
    --skip-email \
    --allow-root

echo "Creando segundo usuario..."
$WP user create "$WP_USER" "$WP_USER@student.42.fr" \
    --user_pass="$WP_PASSWORD" \
    --role=author \
    --allow-root

chown -R www-data:www-data /var/www/wordpress
chmod -R 755 /var/www/wordpress

echo "Iniciando PHP-FPM..."
exec /usr/sbin/php-fpm82 -F
