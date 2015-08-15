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

DOCKER        := docker
DOCKER_TAG    := restswitch/server_nginx
DOCKER_IMGS   := $$(docker images | grep "$(DOCKER_TAG)")
DOCKER_CONTS  := $$(docker ps -a | grep "$(DOCKER_TAG)" | cut -d' ' -f1 | xargs)


.DEFAULT all: docker

docker:
    ifeq ("","$(DOCKER_IMGS)")
	@docker rmi "$(DOCKER_TAG)"
    endif
	@docker build -t "$(DOCKER_TAG):latest" $(DOCKER)

run:
	@docker run -d -p 80:80 "$(DOCKER_TAG):latest"

run-ssl:
	@docker run -d -p 80:80 -p 443:443 "$(DOCKER_TAG):latest"

show:
	@docker images
	@echo ----------------------------------------------------------------------------------------------------
	@docker ps -a

term join:
	# enter our container interactively
	@docker exec -it $$(docker ps | grep "$(DOCKER_TAG)" | cut -d' ' -f1) /bin/bash

stop:
	# stop our running containers
	@docker stop $$(docker ps | grep "$(DOCKER_TAG)" | cut -d' ' -f1 | xargs)

clean:
	# delete our containers (running or stopped)
    ifneq ("","$(DOCKER_CONTS)")
	@docker rm -f $(DOCKER_CONTS)
    endif

distclean: clean
    ifneq ("","$(DOCKER_IMGS)")
	@docker rmi "$(DOCKER_TAG)"
    endif

.PHONY: all docker run run-ssl show term join stop clean distclean

