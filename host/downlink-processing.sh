#!/bin/bash
# SCRIPT TO PROCESS INCOMING MESSAGES FROM CONTAINERS ("DOWNLINKS")

DOWNLINK_PIPE_PATH="$1"
PAT_FILE="$2"
DIR=$(dirname "$DOWNLINK_PIPE_PATH")

REGEX_PATTERN_SET_PAT="^set-pat (ghp_[[:alnum:]]+)$"
REGEX_PATTERN_CHANGE_TO_VERSION="^update$|^fetch[[:space:]](v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\-?[[:alnum:]]*)"
REGEX_PATTERN_UPDATE="^check-update ([[:alnum:][:punct:]äöü]*)$"

startListeningToPipe() {
    printf "==== Listening to \"%s\" ====\n" "$DOWNLINK_PIPE_PATH"
    
    # Load PAT from file
    if [ -f "$PAT_FILE" ]; then
        GITHUB_PAT=$(cat "$PAT_FILE")
    else
        printf "ERROR: PAT file not found at %s\n" "$PAT_FILE"
        exit 1
    fi

    while true; do
        COMMAND="$(cat "$DOWNLINK_PIPE_PATH")"
        timestamp=$(date +%F_%T)
        printf " >> COMMAND: \"%s\"" "$COMMAND"
        printf "%s: %s" "$timestamp" "$COMMAND" | sudo tee -a "$DIR"/downlink.log > /dev/null

        if [[ "$COMMAND" =~ $REGEX_PATTERN_CHANGE_TO_VERSION ]]; then
            VERSION_TAG=${BASH_REMATCH[1]}
            printf "...OK\n"
            printf "...OK\n" | sudo tee -a "$DIR"/downlink.log > /dev/null

            # EXECUTE CODE FOR UPDATE
            # TODO
            printf "    ⤷ Changing \"%s\" to %s\n" "$REPO" "$VERSION_TAG"

            printf "%s" "{return: true}" > /opt/emma/pipes/docker-uplink
        elif [[ "$COMMAND" =~ $REGEX_PATTERN_UPDATE ]]; then
            REPO=${BASH_REMATCH[1]}
            printf "...OK\n"
            printf "...OK\n" | sudo tee -a "$DIR"/downlink.log > /dev/null

            GHCR_TOKEN=$(echo -n "$GITHUB_PAT" | base64)

            # get tags
            TAGS_JSON=$(curl -s -H "Authorization: Bearer ${GHCR_TOKEN}" "https://ghcr.io/v2/${REPO}/tags/list")
            tags=$(_getJSONValue ".tags  | values[]" "$TAGS_JSON")

            tagList=$(echo "$tags" | paste -sd ", " - | sed 's/, $//')
            printf "    ⤷ Tags retrieved for \"%s\": %s\n" "$REPO" "$tagList"
            printf "%s" "$TAGS_JSON" > /opt/emma/pipes/docker-uplink
            printf "    ⤷ Response sent to uplink-pipe\n"
        elif [[ "$COMMAND" =~ $REGEX_PATTERN_SET_PAT ]]; then
            NEW_PAT=${BASH_REMATCH[1]}
            printf "...OK\n"
            printf "...OK\n" | sudo tee -a "$DIR"/downlink.log > /dev/null

            GITHUB_PAT=$NEW_PAT
            echo "$NEW_PAT" > "$PAT_FILE"

            printf "    ⤷ New github PAT set\n"
            printf "%s" "{result: true}" > /opt/emma/pipes/docker-uplink
            printf "    ⤷ Response sent to uplink-pipe\n"
        else
            printf "...Failed (Unknown Command)\n"
         fi

    done
}

_getJSONValue() {
    local selection=$1
    local json=$2
    local result
    result="$(jq -r "$selection" <<< "$json")"
    echo "$result"
}

# RUN MAIN FUNCTION
startListeningToPipe