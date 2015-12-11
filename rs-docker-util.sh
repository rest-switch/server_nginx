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

DOCKER_IMG_NAME='restswitch/server_nginx'
DOCKER_CNT_NAME='restswitch_webserver'


clean() {
    tidy
    # delete our containers (running or stopped)
    echo "stopping and removing containers based on \"${DOCKER_IMG_NAME}\" image..."
    local docker_cnt_all=$(docker ps -a | grep "${DOCKER_IMG_NAME}:" | awk '{print $1}')
    if [ ! -z "${docker_cnt_all}" ]; then
        docker rm -f ${docker_cnt_all}
    fi

    # delete old images (preserve the latest)
    local docker_img_old=$(docker images | grep "^${DOCKER_IMG_NAME}[[:space:]]" | awk '{print $2}' | sort -rn | tail -n+2)
    for ver in ${docker_img_old}; do
        echo "removing docker image: ${DOCKER_IMG_NAME}:${ver}"
        docker rmi -f "${DOCKER_IMG_NAME}:${ver}"
    done
    local docker_img_lver=$(docker images | grep "^${DOCKER_IMG_NAME}[[:space:]]" | awk '{print $2}' | sort -rn | head -n1)
    docker tag -f "${DOCKER_IMG_NAME}:${docker_img_lver}" "${DOCKER_IMG_NAME}:latest"

    # delete untagged images
    local docker_img_untag=$(docker images -qf "dangling=true")
    if [ ! -z "${docker_img_untag}" ]; then
        docker rmi -f ${docker_img_untag}
    fi
}

create() {
    local autostart=$1

    local cnt_running=$(docker ps -q -f "name=${DOCKER_CNT_NAME}")
    if [ ! -z "${cnt_running}" ]; then
        echo
        echo "container \"${DOCKER_CNT_NAME}\" is already running"
        echo "please run \"$(basename "$0") stop\" to stop the running container"
        echo
        exit 1
    fi

    local cnt_stopped=$(docker ps -q -f "name=${DOCKER_CNT_NAME}" -f 'status=exited')
    if [ ! -z "${cnt_stopped}" ]; then
        echo
        echo "container \"${DOCKER_CNT_NAME}\" has already been created but is not running"
        echo "please run \"$(basename "$0") clean\" to remove the stopped container"
        echo
        exit 1
    fi

    echo "creating ${DOCKER_CNT_NAME} container..."
    docker create $([[ "$autostart" = "auto" ]] && echo '--restart=always') --name "${DOCKER_CNT_NAME}" -p "$EXPOSED_HTTP_PORT:80" -p "$EXPOSED_HTTPS_PORT:443" "${DOCKER_IMG_NAME}:latest"
}

debug() {
    # enter a running, or start a new container with bash
    local cnt_running=$(docker ps -q -f "name=${DOCKER_CNT_NAME}")
    if [ -z "${cnt_running}" ]; then
        echo "starting image: ${DOCKER_IMG_NAME}:latest"
        docker run -it "${DOCKER_IMG_NAME}:latest" "/bin/bash"
    else
        echo "entering running container: ${cnt_running}"
        docker exec -it ${cnt_running} /bin/bash
    fi
}

distclean() {
    clean
    local docker_img_all=$(docker images | grep "^${DOCKER_IMG_NAME}" | awk '{print $3}' | sort -u)
    if [ ! -z "${docker_img_all}" ]; then
        docker rmi -f ${docker_img_all}
    fi
}

enter() {
    local cnt_running=$(docker ps -q -f "name=${DOCKER_CNT_NAME}")
    if [ -z "${cnt_running}" ]; then start; fi
    local docker_cnt_run=$(docker ps | grep "${DOCKER_IMG_NAME}:" | awk '{print $1}')
    docker exec -it "${docker_cnt_run}" /bin/bash
}

load() {
    local tarxz_name=$1
    if [ ! -f "${tarxz_name}" ]; then
        echo 'error: tar.xz archive must be specified'
        exit 2;
    fi

    echo "loading image: ${tarxz_name}"
    echo "please wait..."
    cat "${tarxz_name}" | xz -cd | docker load
    echo
    docker images
}

setpass() {
    local email=$1
    local passwd=$2
    if [ -z "${userid}" ] || [ -z "${passwd}" ]; then
        echo 'error: email and password must be specified'
        exit 4;
    fi
    docker exec -it "${DOCKER_CNT_NAME}" "/etc/nginx/conf.d/set_pass.sh" "${email}" "${passwd}"
    docker exec -it "${DOCKER_CNT_NAME}" pkill -HUP nginx
}

show() {
    docker images
    echo '----------------------------------------------------------------------------------------------------'
    docker ps -a
}

start() {
    local cnt_running=$(docker ps -q -f "name=${DOCKER_CNT_NAME}")
    if [ ! -z "${cnt_running}" ]; then
        echo
        echo "container \"${DOCKER_CNT_NAME}\" is already running"
        echo "please run \"$(basename "$0") stop\" to stop the running container"
        echo
        return
    fi

    local cnt_stopped=$(docker ps -q -f "name=${DOCKER_CNT_NAME}" -f 'status=exited')
    if [ -z "${cnt_stopped}" ]; then
        echo
        echo "container \"${DOCKER_CNT_NAME}\" does not exist to start"
        echo "please run \"$(basename "$0") create\" to create the container"
        echo
        exit 1
    fi

    echo "starting ${DOCKER_CNT_NAME}..."
    docker start "${DOCKER_CNT_NAME}"
}

stop() {
    echo "stopping ${DOCKER_CNT_NAME}..."
    docker stop "${DOCKER_CNT_NAME}"
}

tidy() {
    echo 'removing stopped containers...'
    local docker_cnt_exit=$(docker ps -f 'status=exited' | grep "${DOCKER_IMG_NAME}" | awk '{print $1}')
    if [ ! -z "${docker_cnt_exit}" ]; then
        docker rm -f ${docker_cnt_exit}
    fi

    echo 'deleting untagged images...'
    local docker_img_untag=$(docker images -qf 'dangling=true')
    if [ ! -z "${docker_img_untag}" ]; then
        docker rmi -f ${docker_img_untag}
    fi
}


#
# help
#
usage() {
cat << EOF

Usage:
 $(basename "$0") <command>

Commands:
 clean                   remove everything but the ${DOCKER_CNT_NAME} docker image
 create [auto]           create [an autostart on boot] ${DOCKER_CNT_NAME} docker container
 debug                   enter a the running container or start a container using bash
 distclean               remove everything
 enter                   enter a running container (will autocreate and start if needed)
 load <tar.xz>           load an existing image
 run                     alias for start
 setpass <email> <pass>  set credentials for /secure website
 shell                   alias for enter
 show                    show docker image and container information
 start                   start ${DOCKER_CNT_NAME} docker container (will autocreate if needed)
 stop                    stop ${DOCKER_CNT_NAME} docker container
 term                    alias for enter
 terminal                alias for enter
 tidy                    similar to clean, but does not remove container

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
        if [ "${2}" == "auto" ]; then
            create auto
            shift
        else
            create
        fi
        ;;
    debug)
        debug
        ;;
    distclean)
        distclean
        ;;
    enter)
        enter
        ;;
    load)
        load "${2}"
        shift
        ;;
    run)
        start
        ;;
    sethash)
        sethash "${2}" "${3}"
        shift 2
        ;;
    setpass)
        setpass "${2}" "${3}"
        shift 2
        ;;
    shell)
        enter
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
    term)
        enter
        ;;
    terminal)
        enter
        ;;
    tidy)
        tidy
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

