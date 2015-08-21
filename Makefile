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

DOCKER           := docker
DOCKER_TAG       := restswitch/server_nginx
DOCKER_IMG_ALL   := $$(docker images | grep '$(DOCKER_TAG)' | awk '{print $$3}')
DOCKER_IMG_LVER  := $$(docker images | grep '$(DOCKER_TAG)' | awk '{print $$2}' | sort -rn | head -n1)
DOCKER_IMG_OLD   := $$(docker images | grep '$(DOCKER_TAG)' | awk '{print $$2}' | sort -rn | tail -n+2)
DOCKER_CNT_ALL   := $$(docker ps -a | grep '$(DOCKER_TAG)' | awk '{print $$1}')
DOCKER_CNT_RUN   := $$(docker ps | grep '$(DOCKER_TAG)' | awk '{print $$1}')
DOCKER_CNT_EXIT  := $$(docker ps -a | grep '$(DOCKER_TAG)' | grep Exited | awk '{print $$1}')
DOCKER_CNT_DANG  := $$(docker images -qf "dangling=true")
#VER              := $$(echo $$(test -f VERSION && echo $$(($$(cat VERSION)+1)) || echo 1) > VERSION; echo $$(cat VERSION))
VER              := $$(echo $$(($$(cat VERSION 2>/dev/null || echo 100)+1)) > VERSION; echo $$(cat VERSION))


all docker:
	@if [ ! -f "$(DOCKER)/cert-chain-public.pem" ]; then touch "$(DOCKER)/cert-chain-public.pem"; fi
	@if [ ! -f "$(DOCKER)/cert-private.pem" ]; then touch "$(DOCKER)/cert-private.pem"; fi
	@docker build -t "$(DOCKER_TAG):$(VER)" "$(DOCKER)"
	@docker tag -f "$(DOCKER_TAG):$(DOCKER_IMG_LVER)" "$(DOCKER_TAG):latest"

run:
	@if [ -z "$(DOCKER_CNT_RUN)" ]; then \
		echo "starting container: $(DOCKER_TAG):latest"; \
		docker run -d -p 80:80 -p 443:443 "$(DOCKER_TAG):latest"; \
	else \
		echo "found running container: $(DOCKER_CNT_RUN)"; \
	fi

show:
	@docker images
	@echo "----------------------------------------------------------------------------------------------------"
	@docker ps -a

term shell join: run
	# enter container interactively
	@docker exec -it $(DOCKER_CNT_RUN) /bin/bash

stop:
	@if [ ! -z "$(DOCKER_CNT_RUN)" ]; then \
		echo "stopping running container(s): $(DOCKER_CNT_RUN)"; \
		docker stop $(DOCKER_CNT_RUN); \
	fi
	$(MAKE) tidy

tidy:
	# remove all stopped containers
	@if [ ! -z "$(DOCKER_CNT_EXIT)" ]; then \
		docker rm $(DOCKER_CNT_EXIT); \
	fi

	# clean up un-tagged docker images
	@if [ ! -z "$(DOCKER_CNT_DANG)" ]; then \
		docker rmi $(DOCKER_CNT_DANG); \
	fi

clean: stop
	# delete our containers (running or stopped)
	@if [ ! -z "$(DOCKER_CNT_ALL)" ]; then \
		docker rm -f $(DOCKER_CNT_ALL); \
	fi

	# delete old images (preserve the latest)
	@for ver in $(DOCKER_IMG_OLD); do \
		echo "removing docker image: $(DOCKER_TAG):$${ver}"; \
		docker rmi $(DOCKER_TAG):$${ver}; \
	done
	@docker tag -f "$(DOCKER_TAG):$(DOCKER_IMG_LVER)" "$(DOCKER_TAG):latest"

distclean: stop clean
	@if [ ! -z "$(DOCKER_IMG_ALL)" ]; then \
		docker rmi -f $(DOCKER_IMG_ALL); \
	fi


.PHONY: all docker run show term shell join stop tidy clean distclean

