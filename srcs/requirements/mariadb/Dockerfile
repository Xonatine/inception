FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/mysqld /var/lib/mysql && \
	chown -R  mysql:mysql /run/mysqld /var/lib/mysql

COPY ./conf/my.cnf /etc/my.cnf
COPY ./tools/script.sh /usr/local/bin/script.sh

RUN chmod -x /usr/local/bin/script.sh

EXPOSE 3306


ENTRYPOINT ["/usr/local/bin/init_db.sh"]