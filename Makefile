NAME =			discourse
VERSION =		latest
VERSION_ALIASES =	1.4.0 1.4 1
TITLE =			Discourse
DESCRIPTION =		Discourse
SOURCE_URL =		https://github.com/scaleway-community/scaleway-discourse
VENDOR_URL =		https://www.discourse.org

IMAGE_VOLUME_SIZE =	50G
IMAGE_BOOTSCRIPT =	latest
IMAGE_NAME =		Discourse 1.4.0 (BETA)

## Image tools  (https://github.com/scaleway/image-tools)
all:	docker-rules.mk
docker-rules.mk:
	wget -qO - http://j.mp/scw-builder | bash
-include docker-rules.mk
