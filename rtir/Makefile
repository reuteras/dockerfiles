all: up

up:
	docker compose up -d

down:
	docker compose down

rm:
	docker compose rm

clean:
	docker compose stop
	docker compose rm --force

database-upgrade:
	docker compose exec -T --user rt-service --workdir /opt/rt5 rt /opt/rt5/sbin/rt-setup-database --action upgrade

build:
	docker compose build

image-rm:
	docker rmi reuteras/container-rt:latest

dist-clean: down rm clean image-rm

shell-rt:
	docker compose exec rt /bin/bash
