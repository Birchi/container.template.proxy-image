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
This script deploy the container image to the registry.

Parameters:
  -n, --name                Specifies the name of the image. Default value is '${image_name}'.
  -v, --version             Specifies the version of the image. Default value is '${image_version}'.
  --registry                Specifies the container registry.
  --registry-username       Specifies the username of the registry.
  --registry-password       Specifies the password of the registry.
  --registry-tls-verify     Enables the tls verification. Default value is true.

Examples:
  $(dirname $0)/deploy.sh -n ${image_name} -v ${image_version} --registry my.registry.com --registry-username username --registry-password password
  $(dirname $0)/deploy.sh --name ${image_name} --version ${image_version} --registry my.registry.com --registry-username username --registry-password password
EOF
}

function parse_cmd_args() {
    args=$(getopt --options hn:v: \
                  --longoptions help,name:,version:,registry:,registry-username:,registry-password:,registry-tls-verify: -- "$@")
    
    if [[ $? -ne 0 ]]; then
        echo "Failed to parse arguments!" && usage
        exit 1;
    fi

    while test $# -ge 1 ; do
        case "$1" in
            -h | --help) usage && exit 0 ;;
            -n | --name) image_name="$(eval echo $2)" ; shift 1 ;;
            -v | --version) image_version="$(eval echo $2)" ; shift 1 ;;
            --registry) container_registry="$(eval echo $2)" ; shift 1 ;;
            --registry-username) container_registry_username="$(eval echo $2)" ; shift 1 ;;
            --registry-password) container_registry_password="$(eval echo $2)" ; shift 1 ;;
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

if [ "${container_registry}" == "" ] ; then
    validation_error "Please, set the container registry via '--registry my.registry.com'"
fi

if [ "$(get_image_id_by_image_name $image_name $image_version)" == "" ] ; then
    validation_error "Image ${image_name}:${image_version} does not exist!"
fi

if [ "${container_registry_username}" != "" ] && [ "${container_registry_password}" != "" ] ; then
    ${container_engine} login --username ${container_registry_username} \
                              --password ${container_registry_password} \
                              --tls-verify ${container_registry_tls_verify} ${container_registry}
fi

${container_engine} tag ${image_name}:${image_version} ${container_registry}/${image_name}:${image_version}
${container_engine} push ${container_registry}/${image_name}:${image_version}
${container_engine} image rm ${container_registry}/${image_name}:${image_version}
