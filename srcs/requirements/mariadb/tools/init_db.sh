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

FIRST_RUN=false
if [ ! -d "/var/lib/mysql/mysql" ]; then
    FIRST_RUN=true
    echo "First run detected: initializing data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

echo "Starting temporary MariaDB server for setup..."
mysqld --skip-networking --socket=/run/mysqld/mysqld.sock --user=mysql &
pid="$!"

echo "Waiting for MariaDB to be ready..."
until mysqladmin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1; do
    sleep 1
done
echo "MariaDB is ready!"

# --- En el primer arranque, root no tiene contraseña todavía ---
if [ "$FIRST_RUN" = true ]; then
    echo "Setting root password..."
    mysql --socket=/run/mysqld/mysqld.sock -u root -e \
        "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
fi

# --- Reconciliación independiente: se ejecuta SIEMPRE, en cada arranque.
#     Si algo faltó de una vez anterior (fallo parcial), aquí se autorepara.
#     Cada sentencia por separado para que, si una falla, el mensaje de
#     error apunte exactamente a cuál. ---
MYSQL="mysql --socket=/run/mysqld/mysqld.sock -u root -p${MYSQL_ROOT_PASSWORD}"

echo "Ensuring database '${MYSQL_DATABASE}' exists..."
$MYSQL -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"

echo "Ensuring user '${MYSQL_USER}' exists..."
$MYSQL -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"

echo "Ensuring user password is up to date..."
$MYSQL -e "ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"

echo "Granting privileges..."
$MYSQL -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"
$MYSQL -e "FLUSH PRIVILEGES;"

echo "Setup verified. Current databases:"
$MYSQL -e "SHOW DATABASES;"

echo "Shutting down temporary MariaDB..."
mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
wait "$pid" || true

echo "Starting MariaDB..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --socket=/run/mysqld/mysqld.sock
# #!/bin/bash
# set -e

# echo "Starting MariaDB initialization..."

# # --- Leer contraseñas desde los secrets de Docker ---
# if [ -n "$MYSQL_ROOT_PASSWORD_FILE" ] && [ -f "$MYSQL_ROOT_PASSWORD_FILE" ]; then
#     MYSQL_ROOT_PASSWORD=$(cat "$MYSQL_ROOT_PASSWORD_FILE")
# fi
# if [ -n "$MYSQL_PASSWORD_FILE" ] && [ -f "$MYSQL_PASSWORD_FILE" ]; then
#     MYSQL_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")
# fi

# if [ -z "$MYSQL_ROOT_PASSWORD" ] || [ -z "$MYSQL_PASSWORD" ]; then
#     echo "ERROR: MYSQL_ROOT_PASSWORD or MYSQL_PASSWORD is empty. Check your secrets." >&2
#     exit 1
# fi

# if [ ! -d "/var/lib/mysql/mysql" ]; then
#     echo "Initializing data directory..."
#     mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
# fi

# echo "Starting temporary MariaDB server for setup..."
# mysqld --skip-networking --socket=/run/mysqld/mysqld.sock --user=mysql &
# pid="$!"

# echo "Waiting for MariaDB to be ready..."
# until mysqladmin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1; do
#     sleep 1
# done
# echo "MariaDB is ready!"

# echo "Running setup SQL..."
# mysql --socket=/run/mysqld/mysqld.sock -u root << EOF
# ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
# CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
# CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
# GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
# FLUSH PRIVILEGES;
# EOF

# echo "Shutting down temporary MariaDB..."
# mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
# wait "$pid" || true

# echo "Initialization complete. Starting MariaDB..."
# exec mysqld --user=mysql --datadir=/var/lib/mysql --socket=/run/mysqld/mysqld.sock
