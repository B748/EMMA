#!/bin/bash

################################################################################
#
# source: https://github.com/B748/EMMA.git
#
################################################################################
#
# EMMA: Essential Machine Management Automation
# A script for installation automation on Unix-based systems.
#
################################################################################

# Check if a configuration file is provided as an argument
CONFIG_FILE="$1"

if [ -z "$CONFIG_FILE" ]; then
    CONFIG_FILE="config.yaml"
    echo "No configuration file provided. Using default: $CONFIG_FILE"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file '$CONFIG_FILE' not found."
    exit 1
fi

# Define URLs for required files
EMMA_URL="https://raw.githubusercontent.com/B748/EMMA/main"
CONSTANTS_URL="$EMMA_URL/imports/constants.sh"
UI_CODE_URL="$EMMA_URL/imports/ui.sh"

# Fetch and source constants.sh
CONSTANTS_CONTENT=$(curl -sSL "$CONSTANTS_URL")
if [ -n "$CONSTANTS_CONTENT" ]; then
    eval "$CONSTANTS_CONTENT"
else
    exit 1
fi

# Fetch and source ui.sh
UI_CODE_CONTENT=$(curl -sSL "$UI_CODE_URL")
if [ -n "$UI_CODE_CONTENT" ]; then
    eval "$UI_CODE_CONTENT"
else
    exit 1
fi

printSectionHeadline "Welcome to EMMA - Essential Machine Management Automation"
printSectionSubHeadline "Starting setup"


# Parse the YAML file using yq (a lightweight YAML processor)
if ! command -v yq >/dev/null 2>&1; then
    printProgress " ★ Installing package \"yq\"" "$CYAN"
    sudo apt-get install -y yq >/dev/null 2>&1
    printResult 0 $?
else
    printProgress " ★ Checking package \"yq\"" "$CYAN"
    printResult 0 0
fi

# Ensure Git is installed
if ! command -v git >/dev/null 2>&1; then
    printProgress " ★ Installing package \"git\"" "$CYAN"
    sudo apt-get install -y git >/dev/null 2>&1
    printResult 0 $?
else
    printProgress " ★ Checking package \"git\"" "$CYAN"
    printResult 0 0
fi

# Read packages from the YAML configuration file
packages=$(yq '.packages[]' "$CONFIG_FILE")

# Install each package listed in the configuration file
for package in $packages; do
    printProgress " ★ Installing package \"$package\"" "$CYAN"
    sudo apt-get install -y "$package" >/dev/null 2>&1
    printResult 0 $?
done

# Read the PAT and repository URLs from the YAML configuration file
PAT=$(yq '.pat' "$CONFIG_FILE")
repos=$(yq '.repos[]' "$CONFIG_FILE")

if [ -n "$PAT" ] && [ -n "$repos" ]; then
    for repo in $repos; do
        printProgress " ★ Cloning repository \"$repo\"" "$CYAN"
        git clone "https://${PAT}@${repo#https://}" >/dev/null 2>&1
        printResult 0 $?
    done
else
    echo "No repositories or PAT found in the configuration file."
fi

echo "Setup complete. Your system is ready!"
