DOCKER_NAMESPACE =	armbuild/
NAME =			scw-app-discourse
VERSION =		latest
VERSION_ALIASES =	14.10 14 latest utopic 1.2.3
TITLE =			Discourse
DESCRIPTION =		Discourse
SOURCE_URL =		https://github.com/scaleway/image-app-discourse


## Image tools  (https://github.com/scaleway/image-tools)
all:	docker-rules.mk
docker-rules.mk:
	wget -qO - http://j.mp/scw-builder | bash
-include docker-rules.mk


## Here you can add custom commands and overrides

