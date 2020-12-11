FORCE_REBUILD ?= 0
JITSI_RELEASE ?= stable
JITSI_BUILD ?= $(date +"%Y%m%d")
JITSI_REPO ?= cyber5k
#JITSI_SERVICES ?= base base-java web prosody jicofo jvb jigasi jibri
#JITSI_SERVICES ?= web prosody jigasi
JITSI_SERVICES ?= jigasi

BUILD_ARGS := --build-arg JITSI_REPO=$(JITSI_REPO) --build-arg JITSI_RELEASE=$(JITSI_RELEASE)
ifeq ($(FORCE_REBUILD), 1)
  BUILD_ARGS := $(BUILD_ARGS) --no-cache
endif


all:	build-all

release: tag-all push-all

# docker build $(BUILD_ARGS) --progress plain --tag $(JITSI_REPO)/$(JITSI_SERVICE) $(JITSI_SERVICE)/
build:
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	DOCKER_CLI_EXPERIMENTAL=enabled docker buildx create --name builder --driver docker-container --use || true
	DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build --platform=linux/amd64,linux/arm64,linux/arm/v7 --output type=registry $(BUILD_ARGS) --progress plain -t $(JITSI_REPO)/jitsi-$(JITSI_SERVICE):latest -t $(JITSI_REPO)/jitsi-$(JITSI_SERVICE):20201210 $(JITSI_SERVICE)/

$(addprefix build_,$(JITSI_SERVICES)):
	$(MAKE) --no-print-directory JITSI_SERVICE=$(patsubst build_%,%,$@) build

tag:
	docker tag $(JITSI_REPO)/jitsi-$(JITSI_SERVICE):latest $(JITSI_REPO)/jitsi-$(JITSI_SERVICE):$(JITSI_BUILD)

push:
	docker push $(JITSI_REPO)/$(JITSI_SERVICE):latest
	docker push $(JITSI_REPO)/$(JITSI_SERVICE):$(JITSI_BUILD)

%-all:
	@$(foreach SERVICE, $(JITSI_SERVICES), $(MAKE) --no-print-directory JITSI_SERVICE=$(SERVICE) $(subst -all,;,$@))

clean:
	docker-compose stop
	docker-compose rm
	docker network prune

prepare:
	docker pull debian:buster-slim
	FORCE_REBUILD=1 $(MAKE)

.PHONY: all build tag push clean prepare release $(addprefix build_,$(JITSI_SERVICES))
