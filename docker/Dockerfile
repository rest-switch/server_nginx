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
RUN yum -y install nginx && yum clean all

# nginx and conf
COPY nginx /usr/sbin/nginx
COPY nginx.conf /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
COPY make_hash.sh /etc/nginx/conf.d/make_hash.sh
COPY make_pass.sh /etc/nginx/conf.d/make_pass.sh

# nginx html
RUN rm -rf /usr/share/nginx/html
RUN \
  mkdir -p /var/www/restswitch/secure && \
  wget -O- https://github.com/rest-switch/client_www_cp/archive/master.tar.gz | tar --strip-components=1 -xzvC /var/www/restswitch/secure && \
  chown -R root:nginx /var/www/restswitch && \
  chmod -R u+rwX,g+rX-w,o-rwx /var/www/restswitch

# nginx certs
RUN mkdir -p /etc/nginx/conf.d/certs && chown root:nginx /etc/nginx/conf.d/certs && chmod 750 /etc/nginx/conf.d/certs
# chain: cert pub first, ca pub second
COPY cert-chain-public.pem /etc/nginx/conf.d/certs/cert-chain-public.pem
RUN chown root:nginx /etc/nginx/conf.d/certs/cert-chain-public.pem && chmod 640 /etc/nginx/conf.d/certs/cert-chain-public.pem
COPY cert-private.pem /etc/nginx/conf.d/certs/cert-private.pem
RUN chown root:nginx /etc/nginx/conf.d/certs/cert-private.pem && chmod 640 /etc/nginx/conf.d/certs/cert-private.pem

# run
ENV TERM xterm
EXPOSE 80 443
CMD [ "/usr/sbin/nginx" ]

