#!/bin/bash

################################################################################
#
#      EMMA: ESSENTIAL MACHINE MANAGEMENT AUTOMATION
#      A SCRIPT FOR INSTALLATION AUTOMATION ON UNIX-BASED SYSTEMS.
#
################################################################################

trap "exit 1" TERM
export TOP_PID=$$

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

getEssentials
getConfiguration "$1"

printSectionSubHeadline "Welcome to EMMA - Essential Machine Management Automation"
printSectionSubHeadline "Starting setup"

# Ensure Git is installed
if ! command -v git >/dev/null 2>&1; then
    printProgress " ★ Installing package \"git\"" "$CYAN"
    sudo apt-get install -y git >/dev/null 2>&1
    printResult 0 $?
else
    printProgress " ★ Checking package \"git\"" "$CYAN"
    printResult 0 0
fi


eval "$(parse_yaml "$CONFIG_FILE")"

## Read packages from the YAML configuration file
#packages=$(yq '.packages[]' "$CONFIG_FILE")

## Install each package listed in the configuration file
#for package in $packages; do
#    printProgress " ★ Installing package \"$package\"" "$CYAN"
#    sudo apt-get install -y "$package" >/dev/null 2>&1
#    printResult 0 $?
#done
#
## Read the PAT and repository URLs from the YAML configuration file
#PAT=$(yq '.pat' "$CONFIG_FILE")
#repos=$(yq '.repos[]' "$CONFIG_FILE")
#
#if [ -n "$PAT" ] && [ -n "$repos" ]; then
#    for repo in $repos; do
#        printProgress " ★ Cloning repository \"$repo\"" "$CYAN"
#        git clone "https://${PAT}@${repo#https://}" >/dev/null 2>&1
#        printResult 0 $?
#    done
#else
#    echo "No repositories or PAT found in the configuration file."
#fi

echo "Setup complete. Your system is ready!"
