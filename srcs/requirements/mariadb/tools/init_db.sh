#!/bin/bash
set -e

mkdir -p /var/log/mysql
chown mysql:mysql /var/log/mysql

# --- Leer contraseñas desde los secrets de Docker ---
if [ -n "$MYSQL_ROOT_PASSWORD_FILE" ] && [ -f "$MYSQL_ROOT_PASSWORD_FILE" ]; then
    MYSQL_ROOT_PASSWORD=$(cat "$MYSQL_ROOT_PASSWORD_FILE")
fi
if [ -n "$MYSQL_PASSWORD_FILE" ] && [ -f "$MYSQL_PASSWORD_FILE" ]; then
    MYSQL_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")
fi

if [ -z "$MYSQL_ROOT_PASSWORD" ] || [ -z "$MYSQL_PASSWORD" ]; then
    echo "ERROR: MYSQL_ROOT_PASSWORD or MYSQL_PASSWORD is empty. Check your secrets." >&2
    exit 1
fi

# --- Solo inicializamos la primera vez: si /var/lib/mysql/mysql ya existe,
#     la base de datos ya fue creada e inicializada en un arranque anterior. ---
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "First run detected: initializing data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    echo "Starting temporary MariaDB server for setup..."
    mysqld --skip-networking --socket=/run/mysqld/mysqld.sock --user=mysql &
    pid="$!"

    echo "Waiting for MariaDB to be ready..."
    until mysqladmin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1; do
        sleep 1
    done
    echo "MariaDB is ready!"

    echo "Running first-time setup SQL..."
    mysql --socket=/run/mysqld/mysqld.sock -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    echo "Shutting down temporary MariaDB..."
    mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait "$pid" || true

    echo "First-time initialization complete."
else
    echo "Existing data directory found, skipping first-time setup."
fi

echo "Starting MariaDB..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --socket=/run/mysqld/mysqld.sock
