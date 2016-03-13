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
	docker build -t ${REGISTRY}/${AUTHOR}/${NAME}:${VERSION} .

push:
	docker push ${REGISTRY}/${AUTHOR}/${NAME}:${VERSION}

clean:
	docker rmi -f ${REGISTRY}/${AUTHOR}/${NAME}:${VERSION}

test:
	docker run -ti --rm --net=host ${REGISTRY}/${AUTHOR}/${NAME}:${VERSION}
