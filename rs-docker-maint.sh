#!/bin/sh -e
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


EXPOSED_HTTP_PORT=80
EXPOSED_HTTPS_PORT=443


clean() {
    echo 'stopping and removing restswitch_webserver container...'
    docker rm -f 'restswitch_webserver'
}

create() {
    autostart=$1

    is_running=$(docker ps -q -f 'name=restswitch_webserver')
    if [ ! -z $is_running ]; then
        echo
        echo 'container "restswitch_webserver" is already running'
        echo "please run \"$(basename "$0") stop\" to stop the running container"
        echo
        exit 1
    fi

    is_stopped=$(docker ps -q -f 'name=restswitch_webserver' -f 'status=exited')
    if [ ! -z $is_stopped ]; then
        echo
        echo 'container "restswitch_webserver" has already been created but is not running'
        echo "please run \"$(basename "$0") clean\" to remove the stopped container"
        echo
        exit 1
    fi

    echo 'creating restswitch_webserver container...'
    docker create $([[ "$autostart" = "auto" ]] && echo '--restart=always') --name 'restswitch_webserver' -p "$EXPOSED_HTTP_PORT:80" -p "$EXPOSED_HTTPS_PORT:443" 'restswitch/server_nginx:latest'
}

load() {
    tarxz_name=$1
    if [ ! -f ${tarxz_name} ]; then
        echo 'error: tar.xz archive must be specified'
        exit 2;
    fi

    echo "loading image: ${tarxz_name}"
    echo "please wait..."
    cat "${tarxz_name}" | xz -cd | docker load
    echo
    docker images
}

enter() {
    start
    docker exec -it 'restswitch_webserver' /bin/bash
}

setpass() {
    userid=$1
    passwd=$2
    if [ -z $userid ] || [ -z $passwd ]; then
        echo 'error: userid and password must be specified'
        exit 4;
    fi
    docker exec -it 'restswitch_webserver' /etc/nginx/conf.d/make_pass.sh $userid $passwd
    docker exec -it 'restswitch_webserver' pkill -HUP nginx
}

show() {
    docker images
    echo "----------------------------------------------------------------------------------------------------"
    docker ps -a
}

start() {
    is_running=$(docker ps -q -f 'name=restswitch_webserver')
    if [ ! -z $is_running ]; then
        echo
        echo 'container "restswitch_webserver" is already running'
        echo "please run \"$(basename "$0") stop\" to stop the running container"
        echo
        exit 1
    fi

    is_stopped=$(docker ps -q -f 'name=restswitch_webserver' -f 'status=exited')
    if [ -z $is_stopped ]; then
        echo
        echo 'container "restswitch_webserver" does not exist to start'
        echo "please run \"$(basename "$0") create\" to create the container"
        echo
        exit 1
    fi

    echo 'starting restswitch_webserver...'
    docker start 'restswitch_webserver'
}

stop() {
    echo 'stopping restswitch_webserver...'
    docker stop 'restswitch_webserver'
}


#
# help
#
usage() {
cat << EOF

Usage:
 $(basename "$0") <command>

Commands:
 clean                        remove restswitch_webserver docker container
 create [auto]                create [an autostart on boot] restswitch_webserver docker container
 enter                        enter restswitch_webserver interactive shell (will autocreate and start if needed)
 load <tar.xz>                load an image
 setpass <userid> <password>  set credentials for /secure site
 show                         show docker image and container information
 start                        start restswitch_webserver docker container (will autocreate if needed)
 stop                         stop restswitch_webserver docker container

EOF
}


#
# parse command line
#
if [ $# -eq 0 ]; then
    usage
    exit 0
fi

while [ $# -gt 0 ]; do
    case "${1}" in
    clean)
        clean
        ;;
    create)
        create "${2}"
        shift
        ;;
    enter)
        enter
        ;;
    load)
        load "${2}"
        shift
        ;;
    setpass)
        setpass "${2}" "${3}"
        shift
        shift
        ;;
    show)
        show
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    help|-h|--help)
        usage
        exit 0
        ;;
    *)
        usage
        exit 1
        ;;
    esac
    shift
done

