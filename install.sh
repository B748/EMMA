#!/bin/bash

################################################################################
#
#      EMMA: ESSENTIAL MACHINE MANAGEMENT AUTOMATION
#      A SCRIPT FOR INSTALLATION AUTOMATION ON UNIX-BASED SYSTEMS.
#
################################################################################

trap "exit 1" TERM
export TOP_PID=$$

function getEssentialsDebug {
    clear

    source "imports/constants.sh"
    source "imports/tools.sh"
    source "imports/ui.sh"

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

getEssentials

printSectionHeadline "Welcome to EMMA v0.0.1"
printSectionHeadline "Essential Machine Management Automation"
printSectionSubHeadline "Running Setup"

getConfiguration "$1"

# Ensure Git is installed
if ! command -v git >/dev/null 2>&1; then
    printProgress " ★ Installing package \"git\"" "$CYAN"
    sudo apt-get install -y git >/dev/null 2>&1
    printResult 0 $?
else
    printProgress " ★ Checking package \"git\"" "$CYAN"
    printResult 0 0
fi

CONF_packages_="";
CONF_repos_="";

# CREATES VARIABLES NAMED ACC TO YAML, PREFIXED WITH "CONF_"
eval "$(parse_yaml "$CONFIG_FILE" "CONF_")"

printSectionSubHeadline "Installing Packages"

# INSTALL EACH PACKAGE LISTED IN THE CONFIGURATION FILE
for packageVarRef in $CONF_packages_; do
    printProgress " ★ Installing package \"${!packageVarRef}\"" "$CYAN"

    resultText=$(sudo apt-get install -y "${!packageVarRef}" 2>&1) 1>/dev/null
    result=$?

    printResult 0 $result

    if [ "$result" -ne 0 ]; then
        printError "$resultText"
    fi
done

# READ THE PAT AND REPOSITORY URLS FROM THE YAML CONFIGURATION FILE
if [ -n "$CONF_pat" ]; then
    for repoVarRef in $CONF_repos_; do
        repoUrl=${!repoVarRef}

        installRepo "$CONF_pat" "$repoUrl"
    done
else
    printError "No PAT found in the configuration file."
fi


echo "Setup complete. Your system is ready!"
