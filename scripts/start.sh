#!/bin/bash
#####################################################################
#
# Copyright (c) 2022-present, Birchi (https://github.com/Birchi)
# All rights reserved.
#
# This source code is licensed under the MIT license.
#
#####################################################################
# Load config and functions
. $(dirname $0)/cfg/config.sh
. $(dirname $0)/lib/function.sh

##
# Functions
##
function usage() {
    cat << EOF
This script starts a container with the specified image.

Parameters:
  -n, --name      Specifies the name of the container. Default value is '${container_name}'.
  -i, --image     Specifies the image for the container. Default value is '${image_name}'. 
  -v, --version   Specifies the version of the image. Default value is '${image_version}'.
  --start-params  Specifies the start parameter.

Examples:
  $(dirname $0)/start.sh -n ${container_name} -i ${image_name} -v ${image_version}
  $(dirname $0)/start.sh --name ${container_name} --image ${image_name} --version ${image_version}
EOF
}

function parse_cmd_args() {
    args=$(getopt --options n:v:i: \
                  --longoptions name:,version:,image:,start-params -- "$@")
    
    if [[ $? -ne 0 ]]; then
        echo "Failed to parse arguments!" && usage
        exit 1;
    fi

    while test $# -ge 1 ; do
        case "$1" in
            -h | --help) usage && exit 0 ;;
            -n | --name) container_name="$(eval echo $2)" ; shift 1 ;;
            -i | --image) image_name="$(eval echo $2)" ; shift 1 ;;
            -v | --version) image_version="$(eval echo $2)" ; shift 1 ;;
            --start-params) start_parameters="$(eval echo $2)" ; shift 1 ;;
            --) ;;
             *) ;;
        esac
        shift 1
    done
}

##
# Main
##
container_engine=$(detect_container_engine)

parse_cmd_args "$@"

if ${start_cleanup_old_containers} ; then
    container_ids=$(${container_engine} container ls -a | grep "${image_name}:${image_version}" | awk '{print $1}')
    if [ "${container_ids}" != "" ] ; then
        log INFO "Removing containers, which use the image ${image_name}:${image_version}"
        for container_id in ${container_ids} ; do
            {
                log DEBUG "Stopping container ${container_id}"
                ${container_engine} container stop ${container_id} 1> /dev/null
                log DEBUG "Stopped container ${container_id}"
            } || log ERROR "Cannot stop container ${container_id}"
            {
                log DEBUG "Removing container ${container_id}"
                ${container_engine} container rm ${container_id} 1> /dev/null
                log DEBUG "Removed container ${container_id}"
            } || log ERROR "Cannot delete container ${container_id}"
        done
        log DEBUG "Removed containers, which use the image ${image_name}:${image_version}"
    fi
fi

if ${start_cleanup_container_same_name} ; then
    container_id=$(get_container_id_by_name ${container_name})
    if [ "$container_id" != "" ] ; then
        log INFO "Removing container ${container_name} to prevent error during the start."
        {
            log DEBUG "Stopping container ${container_id}"
            ${container_engine} container stop ${container_id} 1> /dev/null
            log DEBUG "Stopped container ${container_id}"
        } || log ERROR "Cannot stop container ${container_id}"
        {
            log DEBUG "Removing container ${container_id}"
            ${container_engine} container rm ${container_id} 1> /dev/null
            log DEBUG "Removed container ${container_id}"
        } || log ERROR "Cannot delete container ${container_id}"
        log DEBUG "Removed container to prevent start from failing."
    fi
fi
{
    log INFO "Starting container ${container_name} with image ${image_name}:${image_version}."
    container_hash=$(${container_engine} run -dit --name ${container_name} ${image_name}:${image_version})
    log INFO "Started container ${container_name} with hash '${container_hash}'."
} || error "Failed to start container ${container_name}"
