#!/bin/bash
COM_SYS_DOCKER_PATH="$1"
while true; do
    COMMAND="$(cat $COM_SYS_DOCKER_PATH)"
    echo $COMMAND >> input.log
    #eval "$(cat $COM_SYS_DOCKER_PATH)";
done