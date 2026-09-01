NAME        = inception
COMPOSE_FILE = /srcs/docker-compose.yml
DATA_PATH   = /home/$(USER)/data

all:up

up:
	@mkdir -p $(DATA_PATH)/db
	@mkdir -p $(DATA_PATH)/wordpress
	docker compose -f $(COMPOSE_FILE) up --build -d

down:
	docker compose -f $(COMPOSE_FILE) down

clean: down
	docker system prune -a -f

fclean: clean
	docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@rm -rf $(DATA_PATH)

re: fclean all

ps:
	docker ps

mariadbLogs:
	docker logs mariadb

wordpressLogs:
	docker logs wordpress

nginxLogs:
	docker logs nginx

.PHONY: all up down clean fclean re ps mariadbLogs wordpressLogs nginxLogs