VERSION="1.0.2"
NAME="sp-demo"
REPOSITORY="shibboleth"
IMAGE_NAME="${REPOSITORY}/${NAME}:${VERSION}"

build:
	@echo "Building docker image: ${IMAGE_NAME}"
	@docker build -t ${IMAGE_NAME} .
