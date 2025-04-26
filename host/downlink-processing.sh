#!/bin/bash

# SCRIPT TO PROCESS INCOMING MESSAGES FROM CONTAINERS ("DOWNLINKS")

DOWNLINK_PIPE_PATH="$1"
DIR=$(dirname "$DOWNLINK_PIPE_PATH")
REGEX_PATTERN_UPDATE="^update[[:space:]]?(v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+)?"

while true; do
    COMMAND="$(cat $DOWNLINK_PIPE_PATH)"
    echo "$COMMAND" | sudo tee -a "$DIR"/input.log > /dev/null

    if [[ "$COMMAND" =~ $REGEX_PATTERN_UPDATE ]]; then
        VERSION_TAG=${BASH_REMATCH[1]}
        echo "Starting Update:" "$VERSION_TAG"

        # EXECUTE CODE FOR UPDATE
        # TODO
    fi
done