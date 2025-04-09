#!/bin/bash

# EMMA: Essential Machine Management Automation
# A simple script to demonstrate automation on Unix-based systems.

echo "Welcome to EMMA - Essential Machine Management Automation"
echo "Starting setup..."

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
