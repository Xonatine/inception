FROM debian:bookworm

# Install MariaDB
RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /run/mysqld /var/lib/mysql \
    && chown -R mysql:mysql /run/mysqld /var/lib/mysql \
    && chmod 755 /run/mysqld

# Copy configuration
COPY ./conf/mariadb.conf /etc/mysql/mariadb.conf
COPY ./tools/init_db.sh /usr/local/bin/init_db.sh

# Set permissions
RUN chmod +x /usr/local/bin/init_db.sh

# Environment variables (can be overridden at runtime)
ENV MYSQL_ROOT_PASSWORD=root \
    MYSQL_DATABASE=app_db \
    MYSQL_USER=app_user \
    MYSQL_PASSWORD=app_pass

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init_db.sh"]