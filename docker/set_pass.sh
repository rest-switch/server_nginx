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


EMAIL="$1"
PASSWD="$2"
REPLACE="$3"
if [ -z $EMAIL ] || [ -z $PASSWD ]; then
    echo
    echo "usage: $(basename $0) <email> <password> [replace file (y/N)]"
    echo
    exit 1
fi

MYFILE=$(readlink -f "$0")
MYDIR=$(dirname "${MYFILE}")
PASS_FILE="${MYDIR}/passwd"

# hmac sha256 hash, base64url encoded
HASH=$(echo -n "$EMAIL" | openssl dgst -sha256 -hmac "$PASSWD" -binary | openssl enc -base64 | tr -d '=' | tr '/+' '_-')
sed -i "s/hmac_auth_secret.*$/hmac_auth_secret    \"$HASH\";/g" "/etc/nginx/nginx.conf"

CRYPT=$(python -c "import crypt; print crypt.crypt(\"$PASSWD\", crypt.mksalt(crypt.METHOD_SHA256))")

if [ 0 -eq $(echo "$REPLACE" | grep -q -i -e "^y$" -e "^yes$" -e "^t$" -e "^true$" -e "^1$" ; echo $?) ]; then
    rm -rf "${PASS_FILE}"
    touch "${PASS_FILE}"
fi
chown root:nginx "${PASS_FILE}"
chmod 640 "${PASS_FILE}"
echo "$EMAIL:$CRYPT" >> "${PASS_FILE}"

