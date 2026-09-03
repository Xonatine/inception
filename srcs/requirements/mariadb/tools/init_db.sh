#!/bin/ash

set -e
SQL_PASSWORD=$(cat /run/secrets/db_password)
SQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MARIADB_USER=mysql
MARIADB_DATA_DIR=/var/lib/mysql

if [ ! -d "$MARIADB_DATA_DIR/mysql" ]; then
    echo "Iniciando instalación de DB..."
    mariadb-install-db --user=$MARIADB_USER --datadir=$MARIADB_DATA_DIR

    mariadbd --user=$MARIADB_USER --datadir=$MARIADB_DATA_DIR &
    pid=$!

    # Esperar a que arranque
    while ! mariadb -u root -e "SELECT 1" >/dev/null 2>&1; do
        sleep 1
    done

    echo "Configurando base de datos y usuarios..."
    mariadb -u root <<-EOSQL
        CREATE DATABASE IF NOT EXISTS \`$SQL_DATABASE\`;
        CREATE USER IF NOT EXISTS '$SQL_USER'@'%' IDENTIFIED BY '$SQL_PASSWORD';
        GRANT ALL PRIVILEGES ON \`$SQL_DATABASE\`.* TO '$SQL_USER'@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('$SQL_ROOT_PASSWORD');
        FLUSH PRIVILEGES;
EOSQL

    echo "Apagando MariaDB temporal..."
    mariadb-admin -u root -p"$SQL_ROOT_PASSWORD" shutdown
    wait $pid
fi

echo "MariaDB configurada. Lanzando daemon principal..."
exec mariadbd --user=mysql --datadir=$MARIADB_DATA_DIR
