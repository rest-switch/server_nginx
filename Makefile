#
# Copyright 2015 The REST Switch Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its
# Contributions) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied, including,
# without limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A PARTICULAR
# PURPOSE. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any
# risks associated with Your exercise of permissions under this License.
#
# Author: John Clark (johnc@restswitch.com)
#

EXPOSED_HTTP_PORT  = 80
EXPOSED_HTTPS_PORT = 443

DOCKER            := docker
DOCKER_TAG        := restswitch/server_nginx
DOCKER_BUILD      := $(DOCKER)/docker_build
DOCKER_BUILD_TAG  := restswitch/server_nginx_build
NGINX             := $(DOCKER)/nginx
DOCKER_IMG_ALL    := $$(docker images | grep '^$(DOCKER_TAG)[[:space:]]' | awk '{print $$3}')
DOCKER_IMG_LVER   := $$(docker images | grep '^$(DOCKER_TAG)[[:space:]]' | awk '{print $$2}' | sort -rn | head -n1)
DOCKER_IMG_OLD    := $$(docker images | grep '^$(DOCKER_TAG)[[:space:]]' | awk '{print $$2}' | sort -rn | tail -n+2)
DOCKER_IMG_UNTAG  := $$(docker images -qf "dangling=true")
DOCKER_CNT_ALL    := $$(docker ps -a | grep '$(DOCKER_TAG):' | awk '{print $$1}')
DOCKER_CNT_RUN    := $$(docker ps | grep '$(DOCKER_TAG):' | awk '{print $$1}')
DOCKER_CNT_EXIT   := $$(docker ps -f 'status=exited' | grep '$(DOCKER_TAG):' | awk '{print $$1}')
#VER               := $$(echo $$(test -f VERSION && echo $$(($$(cat VERSION)+1)) || echo 1) > VERSION; echo $$(cat VERSION))
VER               := $$(echo $$(($$(cat VERSION 2>/dev/null || echo 100)+1)) > VERSION; echo $$(cat VERSION))


all docker: nginx stop
	@if [ ! -f "$(DOCKER)/cert-chain-public.pem" ]; then touch "$(DOCKER)/cert-chain-public.pem"; fi
	@if [ ! -f "$(DOCKER)/cert-private.pem" ]; then touch "$(DOCKER)/cert-private.pem"; fi
	@docker build -t "$(DOCKER_TAG):$(VER)" "$(DOCKER)"
	@docker tag -f "$(DOCKER_TAG):$(DOCKER_IMG_LVER)" "$(DOCKER_TAG):latest"
	@echo
	@echo 'the docker image is now built'
	@echo ' - to run this image locally, run: "make run"'
	@echo ' - to run this image remotely, run: "make deploy"'
	@echo

start run:
	@if [ -z "$(DOCKER_CNT_RUN)" ]; then \
		echo "starting container: $(DOCKER_TAG):latest"; \
		docker run -d -p "$(EXPOSED_HTTP_PORT):80" -p "$(EXPOSED_HTTPS_PORT):443" "$(DOCKER_TAG):latest"; \
	else \
		echo "found running container: $(DOCKER_CNT_RUN)"; \
	fi

deploy:
	@echo "deploying the latest docker image, please wait..."
	@if [ -z $$(which pv) ]; then \
		echo; \
		echo "   (this may take a couple of minutes, install pv to get a progress indicator)"; \
		echo; \
		docker save '$(DOCKER_TAG):latest' | \
			xz -z > "restswitch_web_docker_$$(docker images | grep '^$(DOCKER_TAG)[[:space:]]*latest' | awk '{print $$3}').tar.xz"; \
	else \
		docker save '$(DOCKER_TAG):latest' | \
			pv -s $$(docker inspect '$(DOCKER_TAG):latest' | grep VirtualSize | awk '{printf "%.0f", $$2 * 1.04}') | \
			xz -z > "restswitch_web_docker_$$(docker images | grep '^$(DOCKER_TAG)[[:space:]]*latest' | awk '{print $$3}').tar.xz"; \
	fi
	@echo "docker image packaging now complete: \033[1;32mrestswitch_web_docker_$$(docker images | grep '^$(DOCKER_TAG)[[:space:]]*latest' | awk '{print $$3}').tar.xz\033[0m"
	@echo "use the \033[0;32mrs-docker-util.sh\033[0m script to help manage this image:\033[0;32m"
	@ls -al "rs-docker-util.sh"
	@echo "\033[0m"

nginx: | $(NGINX)
$(NGINX):
	docker build -t "$(DOCKER_BUILD_TAG)" "$(DOCKER_BUILD)"
	docker run -it "$(DOCKER_BUILD_TAG)"
	docker cp $$(docker ps -a | grep "$(DOCKER_BUILD_TAG)" | awk '{print $$1}' | head -n1):/home/buildd/nginx $(DOCKER)
	-docker rm -f $$(docker ps -a | grep '$(DOCKER_BUILD_TAG)' | awk '{print $$1}')

show:
	@docker images
	@echo "----------------------------------------------------------------------------------------------------"
	@docker ps -a

enter term terminal shell: run
	# enter container interactively
	@docker exec -it $(DOCKER_CNT_RUN) /bin/bash

debug:
	# start a new (or enter a running) container with bash
	@if [ -z "$(DOCKER_CNT_RUN)" ]; then \
		echo "starting container: $(DOCKER_TAG):latest"; \
		@docker run -it "$(DOCKER_TAG):latest" "/bin/bash"; \
	else \
		echo "found running container: $(DOCKER_CNT_RUN)"; \
		@docker exec -it $(DOCKER_CNT_RUN) /bin/bash
	fi

stop:
	@if [ ! -z "$(DOCKER_CNT_RUN)" ]; then \
		echo "stopping running container(s): $(DOCKER_CNT_RUN)"; \
		docker stop $(DOCKER_CNT_RUN); \
	fi
	$(MAKE) tidy

tidy:
	# remove all stopped containers
	@if [ ! -z "$(DOCKER_CNT_EXIT)" ]; then \
		docker rm -f $(DOCKER_CNT_EXIT); \
	fi

	# delete untagged images
	@if [ ! -z "$(DOCKER_IMG_UNTAG)" ]; then \
		docker rmi -f $(DOCKER_IMG_UNTAG); \
	fi

clean: stop
	rm -rf "$(NGINX)"

	# delete our containers (running or stopped)
	@if [ ! -z "$(DOCKER_CNT_ALL)" ]; then \
		docker rm -f $(DOCKER_CNT_ALL); \
	fi

	# delete old images (preserve the latest)
	@if [ ! -z "$(DOCKER_IMG_OLD)" ]; then \
		for ver in $(DOCKER_IMG_OLD); do \
			echo "removing docker image: $(DOCKER_TAG):$${ver}"; \
			docker rmi -f $(DOCKER_TAG):$${ver}; \
		done; \
	fi

	# tag latest version
	@if [ ! -z "$(DOCKER_IMG_LVER)" ]; then \
		@docker tag -f "$(DOCKER_TAG):$(DOCKER_IMG_LVER)" "$(DOCKER_TAG):latest"; \
	fi

	# delete untagged images
	@if [ ! -z "$(DOCKER_IMG_UNTAG)" ]; then \
		docker rmi -f $(DOCKER_IMG_UNTAG); \
	fi

distclean: stop clean
	@if [ ! -z "$(DOCKER_IMG_ALL)" ]; then \
		docker rmi -f $(DOCKER_IMG_ALL); \
	fi

	@if [ ! -z "$$(docker images | grep '$(DOCKER_BUILD_TAG)')" ]; then \
		docker rmi -f $$(docker images | grep '$(DOCKER_BUILD_TAG)' | awk '{print $$3}'); \
	fi

.PHONY: all docker start run deploy nginx show enter term terminal shell debug stop tidy clean distclean

