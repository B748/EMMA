#!/bin/bash

# EMMA: Essential Machine Management Automation
# A simple script to demonstrate automation on Unix-based systems.

echo "Welcome to EMMA - Essential Machine Management Automation"
echo "Starting setup..."

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
CONSTANTS_URL="https://raw.githubusercontent.com/B748/EMMA/main/constants.sh"
PRINT_PROGRESS_URL="https://raw.githubusercontent.com/B748/EMMA/main/print-progress.sh"

# Fetch and source constants.sh
echo "Loading constants file..."
CONSTANTS_CONTENT=$(curl -sSL "$CONSTANTS_URL")
if [ -n "$CONSTANTS_CONTENT" ]; then
    eval "$CONSTANTS_CONTENT"
    echo "Constants loaded successfully."
else
    echo "Failed to load constants file."
    exit 1
fi

# Fetch and source print-progress.sh
echo "Loading print-progress file..."
PRINT_PROGRESS_CONTENT=$(curl -sSL "$PRINT_PROGRESS_URL")
if [ -n "$PRINT_PROGRESS_CONTENT" ]; then
    eval "$PRINT_PROGRESS_CONTENT"
    echo "Print-progress functions loaded successfully."
else
    echo "Failed to load print-progress file."
    exit 1
fi

# Parse the YAML file using yq (a lightweight YAML processor)
if ! command -v yq >/dev/null 2>&1; then
    printProgress "Installing yq (YAML processor)" "$YELLOW"
    sudo apt-get install -y yq >/dev/null 2>&1
    printResult 0 $?
fi

# Read packages from the YAML configuration file
packages=$(yq eval '.packages[]' "$CONFIG_FILE")

# Install each package listed in the configuration file
for package in $packages; do
    printProgress "Installing $package" "$YELLOW"
    sudo apt-get install -y "$package" >/dev/null 2>&1
    printResult 0 $?
done

echo "Setup complete. Your system is ready!"
