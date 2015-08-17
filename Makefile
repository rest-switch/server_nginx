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
DOCKER_IMG       := $$(docker images | grep '$(DOCKER_TAG)')
DOCKER_CNT_ALL   := $$(docker ps -a | grep '$(DOCKER_TAG)' | cut -d' ' -f1 | xargs)
DOCKER_CNT_RUN   := $$(docker ps | grep '$(DOCKER_TAG)' | cut -d' ' -f1 | xargs | cut -d' ' -f1)
DOCKER_CNT_EXIT  := $$(docker ps -a | grep Exited | cut -d' ' -f1 | xargs)
DOCKER_CNT_DANG  := $$(docker images -qf "dangling=true" | xargs)


all docker: tidy
	@if [ ! -f "$(DOCKER)/cert-chain-public.pem" ]; then touch "$(DOCKER)/cert-chain-public.pem"; fi
	@if [ ! -f "$(DOCKER)/cert-private.pem" ]; then touch "$(DOCKER)/cert-private.pem"; fi
	@docker build -t "$(DOCKER_TAG):latest" $(DOCKER)

run:
	@if [ -z "$(DOCKER_CNT_RUN)" ]; then \
		echo "starting container: $(DOCKER_TAG)"; \
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

tidy: stop
	# remove all stopped containers
	@if [ ! -z "$(DOCKER_CNT_EXIT)" ]; then \
		docker rm $(DOCKER_CNT_EXIT); \
	fi

	# clean up un-tagged docker images
	@if [ ! -z "$(DOCKER_CNT_DANG)" ]; then \
		docker rmi $(DOCKER_CNT_DANG); \
	fi

clean: tidy
	# delete our containers (running or stopped)
	@if [ ! -z "$(DOCKER_CNT_ALL)" ]; then \
		docker rm -f $(DOCKER_CNT_ALL); \
	fi

distclean: clean
	@if [ ! -z "$(DOCKER_IMG)" ]; then \
		docker rmi -f $(DOCKER_IMG); \
	fi

.PHONY: all docker run show term shell join stop tidy clean distclean

