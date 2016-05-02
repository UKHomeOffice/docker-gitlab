#
#  vim:ts=2:sw=2:et
#
NAME=docker-gitlab
AUTHOR ?= ukhomeofficedigital
REGISTRY ?= quay.io
VERSION ?= latest

.PHONY: build test

default: build

build:
	@echo "--> Builing the docker image: ${REGISTRY}/${AUTHOR}/${NAME}:${VERSION}"
	docker build -t ${REGISTRY}/${AUTHOR}/${NAME}:${VERSION} .

push:
	@echo "--> Pushing the image to respository"
	docker push ${REGISTRY}/${AUTHOR}/${NAME}:${VERSION}

clean:
	@echo "--> Performing a cleanup"
	docker rmi -f ${REGISTRY}/${AUTHOR}/${NAME}:${VERSION}

test:
	@echo "--> Running the Redis service"
	@docker run -d --name=gitlab-redis redis
	@echo "--> Running the MySQL database"
	@docker run -d --name=gitlab-mysql -e MYSQL_USER="gitlab" -e MYSQL_PASS="password" -e ON_CREATE_DB="gitlab" tutum/mysql
	@echo "--> Running the Gitlab service, https://localhost:8080 + ssh://localhost:8022"
	@docker run -ti --rm  \
		--link=gitlab-redis:redis \
		--link=gitlab-mysql:mysql \
		-p 8080:80 \
		-p 8022:22 \
		-e DEBUG=True \
		-e GITLAB_ROOT_PASSWORD="password" \
		-e GITLAB_TIMEZONE="UTC" \
		-e GITLAB_HTTPS=false \
		-e GITLAB_PORT=8080 \
		-e GITLAB_SSH_PORT=8022 \
		-e REDIS_HOST=redis \
		-e REDIS_PORT=6379 \
		-e GITLAB_SECRETS_DB_KEY_BASE=nH64ETWTZmatUucUPxC5min9vVYxRgkJ \
		-e DB_ADAPTER=mysql2 \
		-e DB_HOST=mysql \
		-e DB_NAME=gitlab \
		-e DB_USER=gitlab \
		-e DB_PASS=password \
		${REGISTRY}/${AUTHOR}/${NAME}:${VERSION} || true
	@echo "--> Deleting the Redis service"
	@docker kill gitlab-redis >/dev/null 2>&1
	@docker rm -v gitlab-redis >/dev/null 2>&1
	@echo "--> Deleting the MySQL service"
	@docker kill gitlab-mysql >/dev/null 2>&1
	@docker rm -v gitlab-mysql >/dev/null 2>&1
