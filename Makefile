#
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
	@docker run -d --net=host --name=gitlab-redis redis
	@echo "--> Running the MySQL database"
	@docker run -d --name=gitlab-mysql \
		--net=container:gitlab-redis \
		-e MYSQL_ROOT_PASSWORD="password" \
		-e MYSQL_DATABASE="gitlab" \
		mariadb:latest
	@echo "--> Running the Gitlab service, https://localhost:8080 + ssh://localhost:8022"
	@docker run -ti --rm  \
		--net=container:gitlab-redis \
		-e DEBUG="true" \
		-e GITLAB_TIMEZONE="UTC" \
		-e GITLAB_HTTPS="false" \
		-e GITLAB_PORT="8080" \
		-e GITLAB_SSH_PORT="8022" \
		-e REDIS_HOST="127.0.0.1" \
		-e REDIS_PORT="6379" \
		-e GITLAB_EMAIL="gitlab@digital.homeoffice.gov.uk" \
		-e GITLAB_SECRETS_SECRET_KEY_BASE=Qw9Jw9mhWFHoUT8bgwo3kvSghPJvUmClrQOi87Z8vzziHMijIlF74Q9lHc76PfnK \
		-e GITLAB_SECRETS_OTP_KEY_BASE=QqltrpiLXxYIaRSSC9KPDbLNOFCybEJ6ZxcFMFzfpvhhOb9CJqfSpGePIyDgZGxE \
		-e SMTP_HOST="email-smtp.eu-west-1.amazonaws.com" \
		-e SMTP_PORT="587" \
		-e SMTP_DOMAIN="digital.homeoffice.gov.uk" \
		-e SMTP_TLS="false" \
		-e SMTP_STARTTLS="true"\
		-e SMTP_USER="FAKE" \
		-e SMTP_PASS="FAKE" \
		-e GITLAB_SECRETS_DB_KEY_BASE="nH64ETWTZmatUucUPxC5min9vVYxRgkJ" \
		-e DB_ADAPTER="mysql2" \
		-e DB_HOST="127.0.0.1" \
		-e DB_NAME="gitlab" \
		-e DB_USER="root" \
		-e DB_PASS="password" \
		-e OAUTH_ENABLED="true" \
		-e OAUTH_ALLOW_SSO="saml" \
		-e OAUTH_BLOCK_AUTO_CREATED_USERS="true" \
		-e OAUTH_AUTO_LINK_SAML_USER="true" \
		-e OAUTH_EXTERNAL_PROVIDERS="saml" \
		-e OAUTH_SAML_LABEL="HOD SSO" \
		-e OAUTH_SAML_ASSERTION_CONSUMER_SERVICE_URL="http://localhost:8080/users/auth/saml/callback" \
		-e OAUTH_SAML_IDP_CERT_FINGERPRINT="76:DE:5A:42:25:90:AA:36:B4:E4:40:6A:EE:45:15:D2:3D:5C:ED:4C" \
		-e OAUTH_SAML_IDP_SSO_TARGET_URL="https://sso.digital.homeoffice.gov.uk/auth/realms/hod-ops/protocol/saml" \
		-e OAUTH_SAML_ISSUER="gitlab" \
		-e OAUTH_SAML_NAME_IDENTIFIER_FORMAT="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified" \
		-e OAUTH_SAML_ATTRIBUTE_STATEMENTS_FIRST_NAME="urn:oid:2.5.4.42" \
		-e OAUTH_SAML_ATTRIBUTE_STATEMENTS_LAST_NAME="urn:oid:2.5.4.4" \
		-e OAUTH_SAML_ATTRIBUTE_STATEMENTS_NAME="urn:oid:2.5.4.42" \
		-e OAUTH_SAML_ATTRIBUTE_STATEMENTS_EMAIL="urn:oid:1.2.840.113549.1.9.1" \
		${REGISTRY}/${AUTHOR}/${NAME}:${VERSION} || true
	@echo "--> Deleting the Redis service"
	@docker kill gitlab-redis >/dev/null 2>&1
	@docker rm -v gitlab-redis >/dev/null 2>&1
	@echo "--> Deleting the MySQL service"
	@docker kill gitlab-mysql >/dev/null 2>&1
	@docker rm -v gitlab-mysql >/dev/null 2>&1
