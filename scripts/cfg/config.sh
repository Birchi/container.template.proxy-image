#!/bin/bash
#####################################################################
#
# Copyright (c) 2022-present, Birchi (https://github.com/Birchi)
# All rights reserved.
#
# This source code is licensed under the MIT license.
#
#####################################################################
# General
LOG_LEVEL=INFO
# Container
container_name=my_container
container_workdir=/
container_shell=/bin/bash
# Image
image_name=my_image
image_version=latest
image_registry_name=image_registry_name
image_registry_version=latest
# Pull
pull_cleanup_old_images=true
# Start
start_cleanup_old_containers=false
start_cleanup_container_same_name=true

