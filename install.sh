#!/bin/bash

############################## GENERAL VARIABLE SETUP #########################

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

EMMA_CONFIG_PATH=$1

trap "exit 1" TERM
export TOP_PID=$$

# DEFINE MAIN URL FOR EMMA REPO
EMMA_URL="https://raw.githubusercontent.com/B748/EMMA/main"

# DEFINE MAIN APP PATH
# shellcheck disable=SC2034
EMMA_DIR="/opt/emma"

############################## ESSENTIAL HOT LOAD FUNCTIONS ###################

function getEssentialsDebug {
    clear

    source "$DIR/imports/constants.sh"
    source "$DIR/imports/tools.sh"
    source "$DIR/imports/ui.sh"
}

function getEssentials {
    clear

    # DEFINE URLS FOR REQUIRED FILES
    CONSTANTS_URL="$EMMA_URL/imports/constants.sh"
    UI_CODE_URL="$EMMA_URL/imports/ui.sh"
    TOOLS_CODE_URL="$EMMA_URL/imports/tools.sh"

    # FETCH AND READ CONSTANTS
    CONSTANTS_CONTENT=$(curl -sSL "$CONSTANTS_URL")
    if [ -n "$CONSTANTS_CONTENT" ]; then
        eval "$CONSTANTS_CONTENT"
    else
        echo "Could not dynamically load required dependency \"$CONSTANTS_URL\". Aborting..."
        kill -s TERM $TOP_PID
    fi

    # FETCH AND READ UI
    UI_CODE_CONTENT=$(curl -sSL "$UI_CODE_URL")
    if [ -n "$UI_CODE_CONTENT" ]; then
        eval "$UI_CODE_CONTENT"
    else
        echo "Could not dynamically load required dependency \"$UI_CODE_URL\". Aborting..."
        kill -s TERM $TOP_PID
    fi

    # FETCH AND READ TOOLS
    TOOLS_CODE_CONTENT=$(curl -sSL "$TOOLS_CODE_URL")
    if [ -n "$TOOLS_CODE_CONTENT" ]; then
        eval "$TOOLS_CODE_CONTENT"
    else
        echo "Could not dynamically load required dependency \"$TOOLS_CODE_URL\". Aborting..."
        exit 1
    fi
}

############################## START SCRIPT ###################################

# FOR PRODUCTION
getEssentials

# FOR DEBUG
#getEssentialsDebug

printHeader "Welcome to EMMA v0.0.1\nEssential Machine Management Automation"

printSection "INSTALLING PREREQUISITES"

prepareSystem "$EMMA_CONFIG_PATH"

setSectionEnd

printEmptyLine

REPOS="$(jq '.repos  | values[]' <<< "$CONFIG_DATA")"
PAT="$(jq '.pat' <<< "$CONFIG_DATA")"
PAT=$(sed -e 's/^"//' -e 's/"$//' <<<"$PAT")

for currentRepoUrl in $REPOS; do
    currentRepoUrl=$(sed -e 's/^"//' -e 's/"$//' <<<"$currentRepoUrl")
    installRepo "$PAT" "$currentRepoUrl"
done
