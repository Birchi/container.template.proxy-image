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
This script builds a container image according to the build file.

Parameters:
  -n, --name                Sets the name of the image. Default value is '${image_name}'.
  -v, --version             Sets the version of the image. Default value is '${image_version}'.
  -r, --registry            Specifies the container registry. Default value is '${container_registry}'.
  --registry-image-name     Specifies the image of the registry. Default value is '${image_registry_name}'.
  --registry-image-version  Specifies the image of the registry. Default value is '${image_registry_version}'.
  -u, --registry-username   Specifies the username of the registry.
  -p, --registry-password   Specifies the password of the registry.
  --registry-tls-verify     Enables the tls verification. Default value is true.

Examples:
  $(dirname $0)/pull.sh -n ${image_name} -v ${image_version} -r ${container_registry} --registry-image-name ${image_registry_name} --registry-image-version ${image_registry_version} -u USERNAME -p PASSWORD"
  $(dirname $0)/pull.sh --name ${image_name} --version ${image_version} --registry "${container_registry} --registry-image-name ${image_registry_name} --registry-image-version ${image_registry_version} --user USERNAME --password PASSWORD"
EOF
}

function parse_cmd_args() {
    args=$(getopt --options n:v:f: \
                  --longoptions name:,version:,registry:,registry-image-name:,registry-image-version:,registry-username:,registry-password:,registry-tls-verify: -- "$@")
    
    if [[ $? -ne 0 ]]; then
        echo "Failed to parse arguments!" && usage
        exit 1;
    fi

    while test $# -ge 1 ; do
        case "$1" in
            -h | --help) usage && exit 0 ;;
            -n | --name) image_name="$(eval echo $2)" ; shift 1 ;;
            -v | --version) image_version="$(eval echo $2)" ; shift 1 ;;
            -r | --registry) container_registry="$(eval echo $2)" ; shift 1 ;;
            --registry-image-name) image_registry_name="$(eval echo $2)" ; shift 1 ;;
            --registry-image-version) image_registry_version="$(eval echo $2)" ; shift 1 ;;
            -u | --registry-username) container_registry_username="$(eval echo $2)" ; shift 1 ;;
            -p | --registry-password) container_registry_password="$(eval echo $2)" ; shift 1 ;;
            --registry-tls-verify) container_registry_tls_verify="$(eval echo $2)" ; shift 1 ;;
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
container_registry=
container_registry_username=
container_registry_password=
container_registry_tls_verify=true

parse_cmd_args "$@"

if ${pull_cleanup_old_images} ; then
    remote_image_ids=$(get_image_id_by_image_name $image_registry_name $image_registry_version)
    if [ "${remote_image_ids}" != "" ] ; then
        for image_id in $remote_image_ids ; do
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
fi

if [ "${container_registry_username}" != "" ] && [ "${container_registry_password}" != "" ] ; then
    ${container_engine} login --username ${container_registry_username} \
                              --password ${container_registry_password} \
                              --tls-verify ${container_registry_tls_verify} ${container_registry}
fi

{
    log INFO "Starting to pull image ${container_registry}/${image_registry_name}:${image_registry_version}" &&
    ${container_engine} pull ${container_registry}/${image_registry_name}:${image_registry_version} 1> /dev/null &&
    ${container_engine} tag ${container_registry}/${image_registry_name}:${image_registry_version} ${image_name}:${image_version} &&
    ${container_engine} image rm ${container_registry}/${image_registry_name}:${image_registry_version} 1> /dev/null &&
    log DEBUG "Finished to pull image ${container_registry}/${image_registry_name}:${image_registry_version}"
} || error "Failed to pull image ${container_registry}/${image_registry_name}:${image_registry_version}"
