#!/bin/bash
COM_SYS_DOCKER_PATH="$1"
DIR=$(dirname "$COM_SYS_DOCKER_PATH")
while true; do
    COMMAND="$(cat $COM_SYS_DOCKER_PATH)"
    echo "$COMMAND" >> "$DIR"/input.log
    #eval "$(cat $COM_SYS_DOCKER_PATH)";
done