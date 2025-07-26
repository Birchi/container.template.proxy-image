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
This script enters a container.

Parameters:
  -n, --name      Specifies the name of the container. Default value is '${container_name}'.
  -w, --workdir   Specifies the workdir of the container. Default value is '${container_workdir}'.
  -s, --shell     Specifies the shell of the container. Default value is '${container_shell}'.

Examples:
  $(dirname $0)/enter.sh -n ${container_name} -w ${container_workdir} -s ${container_shell}
  $(dirname $0)/enter.sh --name ${container_name} --workdir ${container_workdir} --shell ${container_shell}
EOF
}

function parse_cmd_args() {
    args=$(getopt --options n:w:s: \
                  --longoptions name:,workdir:,shell: -- "$@")
    
    if [[ $? -ne 0 ]]; then
        echo "Failed to parse arguments!" && usage
        exit 1;
    fi

    while test $# -ge 1 ; do
        case "$1" in
            -h | --help) usage && exit 0 ;;
            -n | --name) container_name="$(eval echo $2)" ; shift 1 ;;
            -w | --workdir) container_workdir="$(eval echo $2)" ; shift 1 ;;
            -s | --shell) container_shell="$(eval echo $2)" ; shift 1 ;;
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

${container_engine} exec --workdir ${container_workdir}  -it ${container_name} ${container_shell}
