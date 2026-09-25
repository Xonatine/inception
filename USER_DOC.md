# User Documentation

This document explains how to use the Inception stack as an end user or site administrator: what it provides, how to start/stop it, how to log in, where credentials live, and how to check that everything is healthy.

## 1. What services this stack provides

The project runs a complete WordPress website behind an HTTPS reverse proxy, made of three containers:

| Container  | Role                                                              | Reachable from |
|------------|--------------------------------------------------------------------|-----------------|
| `nginx`    | The only entrypoint. Serves the site over HTTPS (port 443, TLSv1.2/1.3 only). | Host machine / browser |
| `wordpress`| Runs the WordPress site itself via PHP-FPM.                        | Internal Docker network only |
| `mariadb`  | Stores all WordPress data (posts, users, settings...).             | Internal Docker network only |

Only `nginx` is reachable from outside the Docker network — WordPress and MariaDB are intentionally not exposed to the host, so the only way to reach the site is through `https://frlorenz.42.fr`.

## 2. Starting and stopping the project

All commands are run from the project root, where the `Makefile` lives.

```bash
make            # builds the images (if needed) and starts all three containers
make down       # stops and removes the containers (data is preserved)
make clean      # stops containers and removes the built images
make fclean     # full cleanup: containers, images, AND the persisted data on disk
make re         # fclean followed by make (full rebuild from scratch)
```

> ⚠️ `make fclean` **deletes your WordPress database and uploaded files** stored in `/home/frlorenz/data`. Only use it when you intentionally want to start over from a blank site.

You can check what's currently running at any time with:
```bash
docker ps
```
All three containers (`nginx`, `wordpress`, `mariadb`) should show `Up` in the `STATUS` column.

## 3. Accessing the website and the admin panel

In your browser:

- **Public site**: `https://frlorenz.42.fr`
- **Admin panel**: `https://frlorenz.42.fr/wp-admin`

Your browser will warn that the certificate is not trusted — this is expected, since the project uses a self-signed TLS certificate (there is no public Certificate Authority for a `.42.fr` internal domain). Click "Advanced" → "Proceed" (wording varies by browser) to continue; the connection is still encrypted.

Always type `https://`, not `http://` — the NGINX container only listens on port 443, by design, so port 80 will simply refuse the connection.

## 4. Locating and managing credentials

All credentials live in the `secrets/` folder at the project root (never inside `srcs/`, and never committed to Git):

| File | Contains |
|---|---|
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/db_password.txt` | Password for the WordPress application database user |
| `secrets/wp_admin_password.txt` | Password for the WordPress administrator account |

The corresponding usernames (not passwords) are set as plain values in `srcs/.env`:
- `MYSQL_USER` — WordPress's database user
- `WP_ADMIN_USER` — WordPress admin login (does **not** contain "admin"/"administrator", per project rules)
- `WP_USER` — the second, non-admin WordPress user

To read a credential without opening the file directly in an editor:
```bash
cat secrets/wp_admin_password.txt
```

To change a password: edit the relevant file under `secrets/`, then recreate the affected container(s) so the new secret is picked up (secrets are only read at container startup):
```bash
docker compose -f srcs/docker-compose.yml up -d --force-recreate wordpress mariadb
```

## 5. Checking that services are running correctly

**Quick check — all containers up:**
```bash
docker ps
```
Expect `nginx`, `wordpress`, `mariadb` all showing `Up` (not `Restarting` or `Exited`).

**NGINX is serving the site:**
```bash
curl -kv https://frlorenz.42.fr
```
Should return WordPress's HTML (a `200 OK` response). The `-k` flag is needed because of the self-signed certificate.

**MariaDB is accepting connections:**
```bash
docker exec mariadb mysqladmin -u root -p"$(cat secrets/db_root_password.txt)" ping
```
Should print `mysqld is alive`.

**WordPress/PHP-FPM is responding:**
```bash
docker logs wordpress --tail 30
```
Should show no errors and end with PHP-FPM's startup line, with no `Waiting for database...` message stuck at the end.

**Reading logs for any service:**
```bash
docker logs <nginx|wordpress|mariadb> --tail 50
```
