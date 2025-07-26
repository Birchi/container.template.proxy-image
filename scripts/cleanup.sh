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
This script removes the container image and all related containers.

Parameters:
  -n, --name                Specifies the name of the image. Default value is '${image_name}'.
  -v, --version             Specifies the version of the image. Default value is '${image_version}'.

Examples:
  $(dirname $0)/cleanup.sh -n ${image_name} -v ${image_version}
  $(dirname $0)/cleanup.sh --name ${image_name} --version ${image_version}
EOF
}

function parse_cmd_args() {
    args=$(getopt --options n:v: \
                  --longoptions name:,version: -- "$@")
    
    if [[ $? -ne 0 ]]; then
        echo "Failed to parse arguments!" && usage
        exit 1;
    fi

    while test $# -ge 1 ; do
        case "$1" in
            -h | --help) usage && exit 0 ;;
            -n | --name) image_name="$(eval echo $2)" ; shift 1 ;;
            -v | --version) image_version="$(eval echo $2)" ; shift 1 ;;
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

# Clean up containers
image_ids=$(get_image_id_by_image_name $image_name $image_version)
if [ "${image_ids}" != "" ] ; then
    for image_id in $image_ids ; do
        container_ids=$(get_containers_by_image_id ${image_id})
        if [ "${container_ids}" != "" ] ; then
            log INFO "Removing containers, which use the image ${image_id}"
            for container_id in ${container_ids} ; do
                {
                    log DEBUG "Stopping container ${container_id}" &&
                    ${container_engine} container stop ${container_id} 1> /dev/null &&
                    log DEBUG "Stopped container ${container_id}"
                } || error "Cannot stop container ${container_id}"
                {
                    log DEBUG "Removing container ${container_id}" &&
                    ${container_engine} container rm ${container_id} 1> /dev/null &&
                    log DEBUG "Removed container ${container_id}"
                } || error "Cannot delete container ${container_id}"
            done
            log DEBUG "Removed containers, which use the image ${image_id}"
        fi
        image_names=$(get_image_names_by_image_id ${image_id})
        if [ "${image_names}" != "" ] ; then
            log INFO "Removing old images with id ${image_id}"
            for image_full_name in $image_names ; do
                {
                    log DEBUG "Removing image ${image_full_name}" &&
                    ${container_engine} image rm ${image_full_name} 1> /dev/null &&
                    log DEBUG "Removed image ${image_full_name}"
                } || error "Cannot remove image ${image_full_name}"
            done
            log DEBUG "Removed old images with id ${image_id}"
        fi
    done
fi
