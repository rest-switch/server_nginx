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
DOCKER_IMGS      := $$(docker images | grep '$(DOCKER_TAG)')
DOCKER_CNTS_ALL  := $$(docker ps -a | grep '$(DOCKER_TAG)' | cut -d' ' -f1 | xargs)
DOCKER_CNTS_RUN  := $$(docker ps | grep '$(DOCKER_TAG)' | cut -d' ' -f1 | xargs | rev | cut -d' ' -f1 | rev)


.DEFAULT all: docker

docker:
	@if [ -z "$(DOCKER_IMGS)" ]; then \
		echo "removing exising images with tag: $(DOCKER_TAG)"; \
		docker rmi "$(DOCKER_TAG)"; \
	fi
	@docker build -t "$(DOCKER_TAG):latest" $(DOCKER)

run:
	@if [ -z "$(DOCKER_CNTS_RUN)" ]; then \
		echo "starting container: $(DOCKER_TAG)"; \
		docker run -d -p 80:80 -p 443:443 "$(DOCKER_TAG):latest"; \
	else \
		echo "found running container: $(DOCKER_CNTS_RUN)"; \
	fi

show:
	@docker images
	@echo "----------------------------------------------------------------------------------------------------"
	@docker ps -a

term shell join: run
	# enter container interactively
	@docker exec -it "$(DOCKER_CNTS_RUN)" /bin/bash

stop:
	@if [ -z "$(DOCKER_CNTS_RUN)" ]; then \
		echo "no containers to stop"; \
	else \
		echo "stopping running container(s): $(DOCKER_CNTS_RUN)"; \
		docker stop "$(DOCKER_CNTS_RUN)"; \
	fi

clean:
	# delete our containers (running or stopped)
	@if [ ! -z "$(DOCKER_CNTS_ALL)" ]; then \
		docker rm -f $(DOCKER_CNTS_ALL); \
	fi

distclean: clean
	@if [ ! -z "$(DOCKER_IMGS)" ]; then \
		docker rmi "$(DOCKER_TAG)"; \
	fi

.PHONY: all docker run run-ssl show term shell join stop clean distclean

