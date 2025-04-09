#!/bin/bash

# EMMA: Essential Machine Management Automation
# A simple script to demonstrate automation on Unix-based systems.

echo "Welcome to EMMA - Essential Machine Management Automation"
echo "Starting setup..."

# Define URLs for required files
CONSTANTS_URL="https://raw.githubusercontent.com/B748/EMMA/main/constants.sh"
PRINT_PROGRESS_URL="https://raw.githubusercontent.com/B748/EMMA/main/print-progress.sh"

# Define file names
CONSTANTS_FILE="constants.sh"
PRINT_PROGRESS_FILE="print-progress.sh"

# Download constants.sh
echo "Downloading constants file..."
curl -sSL -o "$CONSTANTS_FILE" "$CONSTANTS_URL"
if [ -f "$CONSTANTS_FILE" ]; then
    echo "Constants file downloaded successfully."
else
    echo "Failed to download constants file."
    exit 1
fi

# Download print-progress.sh
echo "Downloading print-progress file..."
curl -sSL -o "$PRINT_PROGRESS_FILE" "$PRINT_PROGRESS_URL"
if [ -f "$PRINT_PROGRESS_FILE" ]; then
    echo "Print-progress file downloaded successfully."
else
    echo "Failed to download print-progress file."
    exit 1
fi

# Source the downloaded scripts
source "$CONSTANTS_FILE"
source "$PRINT_PROGRESS_FILE"

# Update the system
printProgress "Updating package lists" "$YELLOW"
sudo apt-get update -y >/dev/null 2>&1
printResult 0 $?

# Install basic tools
printProgress "Installing essential tools" "$YELLOW"
sudo apt-get install -y curl wget git >/dev/null 2>&1
printResult 0 $?

echo "Setup complete. Your system is ready!"

# Add your custom setup tasks below
# For example:
# printProgress "Installing Docker" "$YELLOW"
# sudo apt-get install -y docker.io >/dev/null 2>&1
# printResult 0 $?
