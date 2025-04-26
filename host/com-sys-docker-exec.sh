#!/bin/bash
COM_SYS_DOCKER_PATH="$1"
DIR=$(dirname "$COM_SYS_DOCKER_PATH")
REGEX_UPDATE_PATTERN="^update[[:space:]]?(v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+)?"

while true; do
    COMMAND="$(cat $COM_SYS_DOCKER_PATH)"
    echo "$COMMAND" | sudo tee -a "$DIR"/input.log > /dev/null

    if [[ "$COMMAND" =~ $REGEX_UPDATE_PATTERN ]]; then
        VERSION_TAG=${BASH_REMATCH[1]}
        echo "Starting Update:" "$VERSION_TAG"

        # EXECUTE CODE FOR UPDATE
        # TODO
    fi
done