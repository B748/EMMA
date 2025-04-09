#!/bin/bash

# EMMA: Essential Machine Management Automation
# A simple script to demonstrate automation on Unix-based systems.

echo "Welcome to EMMA - Essential Machine Management Automation"
echo "Starting setup..."

# Define constants file URL
CONSTANTS_URL="https://raw.githubusercontent.com/B748/EMMA/main/constants.sh"
CONSTANTS_FILE="constants.sh"

# Download constants.sh
echo "Downloading constants file..."
curl -sSL -o "$CONSTANTS_FILE" "$CONSTANTS_URL"

if [ -f "$CONSTANTS_FILE" ]; then
    echo "Constants file downloaded successfully."
else
    echo "Failed to download constants file."
    exit 1
fi

# Update the system
echo "Updating package lists..."
sudo apt-get update -y

# Install basic tools
echo "Installing essential tools..."
sudo apt-get install -y curl wget git

echo "Setup complete. Your system is ready!"

# Add your custom setup tasks below
# For example:
# echo "Installing Docker..."
# sudo apt-get install -y docker.io
