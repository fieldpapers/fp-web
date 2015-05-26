NAME = fieldpapers/web
VERSION ?= latest

default:
	docker run --rm \
	  -p 3000:3000 \
	  -v $$(pwd):/app \
	  --env-file .env \
	  $(NAME):$(VERSION)

image:
	docker build --rm -t $(NAME):$(VERSION) .

publish-image:
	docker push $(NAME):$(VERSION)
