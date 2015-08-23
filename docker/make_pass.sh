#!/bin/sh -e

USER="myuser"
PASS="mypass"
FILE="passwd"

CRYPT=$(openssl passwd "$PASS")

rm -rf "${FILE}"
touch "${FILE}"
chown root:nginx "${FILE}"
chmod 640 "${FILE}"
echo "$USER:$CRYPT" > "${FILE}"

