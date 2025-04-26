#!/bin/bash
COM_SYS_DOCKER_PATH="$1"
while true; do
    echo ---"$(cat $COM_SYS_DOCKER_PATH)"---
    #eval "$(cat $COM_SYS_DOCKER_PATH)";
done