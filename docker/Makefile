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

NGINX_SRC_URL   := http://nginx.org/download/nginx-1.8.0.tar.gz
NGINX_ROOT      := nginx-1.8.0
NGINX_MAKEFILE  := $(NGINX_ROOT)/Makefile
NGINX           := $(NGINX_ROOT)/objs/nginx
NGINX_STOCK     := $(shell which nginx)
MOD_PS_SRC_URL  := https://github.com/wandenberg/nginx-push-stream-module/archive/master.tar.gz
MOD_PS_ROOT     := ngx_http_push_stream_module
WWW_CP_SRC_URL  := https://github.com/rest-switch/client_www_cp/archive/master.tar.gz

ifneq ($(shell cat /proc/self/cgroup | grep -q docker ; echo $$?),0)
    $(error not running in a docker container)
endif


all nginx: | $(NGINX_ROOT) $(NGINX_MAKEFILE) www_cp
	make -C "$(NGINX_ROOT)"
	cp "$(NGINX)" "$(NGINX_STOCK)"

$(NGINX_ROOT):
	rm -rf "$(NGINX_ROOT)" && mkdir -p "$(NGINX_ROOT)"
	wget -O- "$(NGINX_SRC_URL)" | tar xzC "$(NGINX_ROOT)" --strip-components 1

modules: | $(MOD_PS_ROOT)
$(MOD_PS_ROOT):
	rm -rf "$(MOD_PS_ROOT)" && mkdir -p "$(MOD_PS_ROOT)"
	wget -O- "$(MOD_PS_SRC_URL)" | tar xzC "$(MOD_PS_ROOT)" --strip-components 1

$(NGINX_MAKEFILE): | $(NGINX_ROOT) modules
	#  --add-module=../ngx_postgres_module \
	cd "$(NGINX_ROOT)"; ./configure \
		--prefix=/usr/share/nginx \
		--sbin-path=/usr/sbin/nginx \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		--http-client-body-temp-path=/var/lib/nginx/tmp/client_body \
		--http-proxy-temp-path=/var/lib/nginx/tmp/proxy \
		--http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi \
		--http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi \
		--http-scgi-temp-path=/var/lib/nginx/tmp/scgi \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/lock/subsys/nginx \
		--user=nginx \
		--group=nginx \
		--with-file-aio \
		--with-ipv6 \
		--with-http_ssl_module \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-google_perftools_module \
		--with-pcre \
		--with-http_auth_request_module \
		--add-module=../$(MOD_PS_ROOT) \
		--with-debug \
		--with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic' \
		--with-ld-opt=' -Wl,-E'

www_cp:
	@rm -rf /usr/share/nginx/html && mkdir -p /usr/share/nginx/html/secure
	@chown -R root:nginx /usr/share/nginx/html && chmod -R 750 /usr/share/nginx/html
	@wget -O- $(WWW_CP_SRC_URL) | tar --strip-components=1 -xzvC /usr/share/nginx/html/secure

	@echo '#!/bin/sh' > /etc/nginx/conf.d/make_pass.sh
	@echo >> /etc/nginx/conf.d/make_pass.sh
	@echo 'USER="myuser"' >> /etc/nginx/conf.d/make_pass.sh
	@echo 'PASS="mypass"' >> /etc/nginx/conf.d/make_pass.sh
	@echo 'FILE="passwd"' >> /etc/nginx/conf.d/make_pass.sh
	@echo >> /etc/nginx/conf.d/make_pass.sh
	@echo 'CRYPT=$$(openssl passwd "$${PASS}")' >> /etc/nginx/conf.d/make_pass.sh
	@echo >> /etc/nginx/conf.d/make_pass.sh
	@echo 'rm -rf "$${FILE}" && touch "$${FILE}"' >> /etc/nginx/conf.d/make_pass.sh
	@echo 'chown root:nginx "$${FILE}" && chmod 640 "$${FILE}"' >> /etc/nginx/conf.d/make_pass.sh
	@echo 'echo "$${USER}:$${CRYPT}" > "$${FILE}"' >> /etc/nginx/conf.d/make_pass.sh
	@echo >> /etc/nginx/conf.d/make_pass.sh

	@chmod 700 /etc/nginx/conf.d/make_pass.sh
	@cd /etc/nginx/conf.d && ./make_pass.sh

.PHONY: all nginx modules www_cp

