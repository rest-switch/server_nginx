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

FROM centos:centos7
MAINTAINER John Clark <johnc@restswitch.com>

RUN yum -y update && yum clean all
RUN yum -y install epel-release tar wget nano && yum clean all
RUN yum -y install gcc make google-perftools-devel pcre-devel openssl-devel && yum clean all

# nginx build
RUN useradd buildd
USER buildd
COPY Makefile /home/buildd/Makefile
COPY ngx_hmac_auth_module /home/buildd/ngx_hmac_auth_module
CMD [ "make","-C","/home/buildd" ]
ENV TERM xterm
USER root

