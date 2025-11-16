#[[file:general.md]]

# Product Overview

## EMMA - Essential Machine Management Automation

- Lightweight Bash-based automation for Unix system setup
- Configures systems via YAML configuration files
- Clones private repositories using GitHub PAT authentication
- Manages Docker containers with bidirectional host communication
- Designed for reproducible system deployments

## Core Capabilities

- Package installation via apt-get
- Private repository cloning with authentication
- Docker Compose orchestration
- Named pipe-based container-host communication (uplink/downlink)
- Pre/post-install script execution
- Reboot-proof background processes via cron

## Communication Architecture

- **Downlink**: Container → Host commands (standardized: `update`, `check-update`, `set-pat`)
- **Uplink**: Host → Container responses
- Pipes located at `/opt/emma/pipes/`
- Security: Only whitelisted commands accepted from containers
- **Primary Use Case**: Version update checking and processing
- Extensible for other container-host communication needs
