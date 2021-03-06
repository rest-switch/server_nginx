#!/bin/sh -e
#
# Copyright 2015 The REST Switch Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this PASS_FILE except in compliance with the License.
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


if [ $# -ne 2 ]; then
    echo
    echo "Usage:"
    echo "  $(basename "$0") <email> <password>"
    echo
    exit 0
fi

EMAIL=$1
PASSWD=$2
NGINX_CONF="/etc/nginx/nginx.conf"

# hmac sha256 hash, base64url encoded
HASH=$(echo -n "$EMAIL" | openssl dgst -sha256 -hmac "$PASSWD" -binary | openssl enc -base64 | tr -d '=' | tr '/+' '_-')
sed -i "s/hmac_auth_secret.*$/hmac_auth_secret    \"$HASH\";/g" "$NGINX_CONF"

