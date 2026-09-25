# Developer Documentation

This document explains how a developer can set up, build, run, and maintain the Inception project from scratch.

## 1. Prerequisites

- A virtual machine running **Debian 12 (bookworm)** — the project's chosen base OS (the penultimate stable Debian release at the time of writing; `trixie`/13 is current stable).
- **Docker Engine** and the **Docker Compose plugin** installed on that VM. See Debian's official install steps: https://docs.docker.com/engine/install/debian/
- `git`, to clone and manage the repository.

## 2. Repository layout

```
.
├── Makefile                     # entrypoint, builds/runs everything via docker compose
├── secrets/                     # confidential values, git-ignored, NOT under srcs/
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── wp_admin_password.txt
└── srcs/
    ├── .env                     # non-sensitive configuration (domain, db name/user, WP users)
    ├── docker-compose.yml       # the 3 services, network, and volumes
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/            # e.g. 50-server.cnf
        │   └── tools/           # init_db.sh (entrypoint)
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/            # nginx.conf.template
        │   └── tools/           # generate_ssl.sh (entrypoint)
        └── wordpress/
            ├── Dockerfile
            ├── conf/            # www.conf (PHP-FPM pool)
            └── tools/           # setup_wordpress.sh (entrypoint)
```

Each service directory is self-contained: its own `Dockerfile`, its own static configuration (`conf/`), and its own entrypoint script (`tools/`). This makes it possible to rebuild and debug one service without touching the others (see section 5).

## 3. Setting up the environment from scratch

### 3.1 Secrets

Create the `secrets/` folder at the project root (sibling to `srcs/`, **not** inside it) and add:

```bash
mkdir -p secrets
echo "your_root_password"  > secrets/db_root_password.txt
echo "your_app_password"   > secrets/db_password.txt
echo "your_admin_password" > secrets/wp_admin_password.txt
chmod 600 secrets/*
```

These files must never be committed — confirm your `.gitignore` includes `secrets/`.

### 3.2 Environment file

Create/edit `srcs/.env` with non-sensitive configuration:

```
DOMAIN_NAME=frlorenz.42.fr

MYSQL_DATABASE=wordpress_db
MYSQL_USER=wp_user

WP_ADMIN_USER=owner_frlorenz
WP_ADMIN_EMAIL=frlorenz@student.42madrid.com
WP_USER=frlorenz
WP_USER_PASSWORD=qwerty
WP_USER_EMAIL=frlorenzDos@student.42madrid.com
```

Notes:
- `WP_ADMIN_USER` must **not** contain "admin"/"administrator" (case-insensitive, with or without extra characters), per project rules.
- Passwords go in `secrets/`, not here — only usernames, the domain, and the database name live in `.env`.

```

## 4. Building and launching the project

Everything goes through the `Makefile` at the project root, which wraps Docker Compose:

```bash
make          # build (if needed) + start all containers, detached
make down     # stop and remove containers (volumes/data kept)
make clean    # + remove built images
make fclean   # + remove persisted data under /home/frlorenz/data
make re       # fclean, then make (full rebuild)
```

Equivalent raw Docker Compose commands, if you need finer control:
```bash
docker compose -f srcs/docker-compose.yml up -d --build   # build + start
docker compose -f srcs/docker-compose.yml down             # stop + remove containers
docker compose -f srcs/docker-compose.yml ps               # status of each service
```

## 5. Useful commands for containers and volumes

**Rebuild a single service** (much faster than rebuilding everything):
```bash
docker compose -f srcs/docker-compose.yml build nginx
docker compose -f srcs/docker-compose.yml up -d nginx
```
Force a rebuild ignoring Docker's layer cache (needed if you edited a file but Docker didn't detect the change — e.g. after editing a `COPY`-ed config template):
```bash
docker compose -f srcs/docker-compose.yml build --no-cache nginx
```

**Follow logs live:**
```bash
docker logs -f wordpress
```

**Get a shell inside a running container:**
```bash
docker exec -it mariadb bash
```

**Query MariaDB directly:**
```bash
docker exec -it mariadb mysql -u root -p"$(cat secrets/db_root_password.txt)"
```

**Inspect the network:**
```bash
docker network inspect srcs_inception-network
```
(shows which containers are attached and their internal IPs — useful when debugging connectivity between services, e.g. `wordpress` failing to reach `mariadb`).

**List and inspect named volumes:**
```bash
docker volume ls
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
```

**Reset everything and start clean** (containers, images, and data):
```bash
make fclean
```

## 6. Where project data is stored, and how it persists

The project uses two **Docker named volumes** (bind mounts are forbidden by the subject for these), both configured with `driver_opts` (`type: none`, `o: bind`) so their underlying storage lives at a specific, predictable host path rather than Docker's internal `/var/lib/docker/volumes/`:

| Volume | Mounted in | Host path | Contains |
|---|---|---|---|
| `mariadb_data` | `mariadb:/var/lib/mysql` | `/home/frlorenz/data/mariadb` | The MariaDB database files |
| `wordpress_data` | `wordpress:/var/www/html` and `nginx:/var/www/html` | `/home/frlorenz/data/wordpress` | WordPress core files, themes, plugins, uploads |

Both volumes are declared once in `docker-compose.yml` under `volumes:` and referenced by name in each service — this is what makes them "named volumes" per Docker's terminology, as opposed to an inline bind mount (`- /host/path:/container/path`), which the subject explicitly disallows for this data.

Because the volumes are managed by Docker (not just files sitting in a folder Docker happens to write to), they:
- Survive `docker compose down` and container recreation — only `docker volume rm` (or `make fclean`, which does this for you) deletes them.
- Are shared correctly between `wordpress` and `nginx` for the website files, so NGINX can serve static assets (images, CSS, JS) directly without going through PHP-FPM, while WordPress itself writes to the same files.

To inspect what's actually stored on disk:
```bash
sudo ls -la /home/frlorenz/data/mariadb
sudo ls -la /home/frlorenz/data/wordpress
```
