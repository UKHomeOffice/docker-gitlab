#
# 
#  vim:ts=2:sw=2:et
#
NAME=gitlab
AUTHOR=gambol99
TAG=8.5.1

.PHONY: build test

default: build

build:
	sudo docker build -t ${AUTHOR}/${NAME}:${TAG} .

push:
	sudo docker tag -f ${AUTHOR}/${NAME}:${TAG} docker.io/${AUTHOR}/${NAME}:${TAG}
	sudo docker push docker.io/${AUTHOR}/${NAME}:${TAG}

clean:
  sudo docker rmi -f ${AUTHOR}/${NAME}:${TAG}

test:
	sudo docker run -ti --rm -e --net=host ${AUTHOR}/${NAME}

