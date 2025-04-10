#!/bin/bash

################################################################################
#
#      EMMA: ESSENTIAL MACHINE MANAGEMENT AUTOMATION
#      A SCRIPT FOR INSTALLATION AUTOMATION ON UNIX-BASED SYSTEMS.
#
################################################################################

DIR="${BASH_SOURCE%/*}"

if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

trap "exit 1" TERM
export TOP_PID=$$

function getEssentialsDebug {
    clear

    source "$DIR/imports/constants.sh"
    source "$DIR/imports/tools.sh"
    source "$DIR/imports/ui.sh"

    local YAML_CODE_URL="https://raw.githubusercontent.com/mrbaseman/parse_yaml/master/src/parse_yaml.sh"

    # FETCH AND READ YAML READER CODE
    local YAML_CODE_CONTENT
    YAML_CODE_CONTENT=$(curl -sSL "$YAML_CODE_URL")

    if [ -n "$YAML_CODE_CONTENT" ]; then
        # IMPORTS THE FUNCTION "parse_yaml" FROM EXTERNAL REPO
        eval "$YAML_CODE_CONTENT"
    else
        echo "Could not dynamically load required dependency for yaml parsing. Aborting..."
        exit 1
    fi
}

function getEssentials {
    clear

    # DEFINE MAIN URL FOR EMMA REPO
    EMMA_URL="https://raw.githubusercontent.com/B748/EMMA/main"

    # DEFINE URLS FOR REQUIRED FILES
    CONSTANTS_URL="$EMMA_URL/imports/constants.sh"
    UI_CODE_URL="$EMMA_URL/imports/ui.sh"
    TOOLS_CODE_URL="$EMMA_URL/imports/tools.sh"
    YAML_CODE_URL="https://raw.githubusercontent.com/mrbaseman/parse_yaml/master/src/parse_yaml.sh"

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

    # FETCH AND READ YAML READER CODE
    YAML_CODE_CONTENT=$(curl -sSL "$YAML_CODE_URL")
    if [ -n "$YAML_CODE_CONTENT" ]; then
        # IMPORTS THE FUNCTION "parse_yaml" FROM EXTERNAL REPO
        eval "$YAML_CODE_CONTENT"
    else
        echo "Could not dynamically load required dependency for yaml parsing. Aborting..."
        exit 1
    fi
}

# FOR PRODUCTION
getEssentials

# FOR DEBUG
#getEssentialsDebug

printHeader "Welcome to EMMA v0.0.1\nEssential Machine Management Automation"

printSection "INSTALLING PREREQUISITES"

prepareSystem "$1"

setSectionEnd

printEmptyLine

for repoVarRef in $CONF_repos_; do
    repoPatVar=${repoVarRef}__pat
    repoUrlVar=${repoVarRef}__url
    repoPat=${!repoPatVar}
    repoUrl=${!repoUrlVar}

    installRepo "$repoPat" "$repoUrl"
done
