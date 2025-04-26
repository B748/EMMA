#!/bin/bash
COM_SYS_DOCKER_PATH="$1"
DIR=$(dirname "$COM_SYS_DOCKER_PATH")
REGEX_UPDATE="^update(?: -v (\d+\.\d+\.\d+))?"

echo $DIR
while true; do
    COMMAND="$(cat $COM_SYS_DOCKER_PATH)"
    echo "$COMMAND" >> "$DIR"/input.log
    if [[ "$COMMAND" =~ $REGEX_UPDATE ]]; then
        echo "Starting Update: " "${BASH_REMATCH[1]}"
    fi

    #eval "$(cat $COM_SYS_DOCKER_PATH)";
done