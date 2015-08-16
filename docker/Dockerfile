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

# update and install
RUN yum -y update && yum -y install epel-release tar wget ; yum clean all
RUN yum -y update && yum -y install gcc make google-perftools-devel openssl-devel pcre-devel nginx ; yum clean all

# nginx conf
ADD nginx.conf /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# nginx certs
RUN mkdir -p /etc/nginx/conf.d/certs && chown root:nginx /etc/nginx/conf.d/certs && chmod 750 /etc/nginx/conf.d/certs
# chain: cert pub first, ca pub second
ADD cert-chain-public.pem /etc/nginx/conf.d/certs/cert-chain-public.pem
RUN chown root:nginx /etc/nginx/conf.d/certs/cert-chain-public.pem && chmod 640 /etc/nginx/conf.d/certs/cert-chain-public.pem
ADD cert-private.pem /etc/nginx/conf.d/certs/cert-private.pem
RUN chown root:nginx /etc/nginx/conf.d/certs/cert-private.pem && chmod 640 /etc/nginx/conf.d/certs/cert-private.pem

# nginx build
RUN mkdir -p /tmp/docker
ADD Makefile /tmp/docker/Makefile
RUN curl https://git.centos.org/sources/httpd/c7/acf5cccf4afaecf3afeb18c50ae59fd5c6504910 \
    | tar -xz -C /usr/share/nginx/html --strip-components=1
RUN sed -i -e 's/Apache/nginx/g' -e '/apache_pb.gif/d' /usr/share/nginx/html/index.html
RUN make -C /tmp/docker ; rm -rf /tmp/docker

# run
EXPOSE 80 443
CMD [ "/usr/sbin/nginx" ]
