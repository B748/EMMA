#[[file:general.md]]

# Technology Stack

## Core Technologies

- **Language**: Bash (shell scripting)
- **Package Manager**: apt-get (Debian/Ubuntu)
- **Container Platform**: Docker + Docker Compose
- **Version Control**: Git

## Required Dependencies

- `curl` - Dynamic script loading, HTTP requests
- `git` - Repository cloning
- `jq` - JSON parsing and manipulation
- `python3` + `yaml` module - YAML to JSON conversion
- `docker` + `docker compose` - Container orchestration

## Key Libraries & Tools

- `tput` - Terminal formatting and colors
- `mkfifo` - Named pipe creation
- `crontab` - Reboot-proof process management
- `nohup` - Background process execution

## Common Commands

### Installation
```bash
# One-liner with default config
curl -sSL https://raw.githubusercontent.com/B748/EMMA/main/install.sh | bash

# One-liner with custom config
curl -sSL https://raw.githubusercontent.com/B748/EMMA/main/install.sh | bash -s -- path/to/config.yaml
```

### Development/Debug
- Switch `getEssentials` to `getEssentialsDebug` in install.sh for local testing
- Debug mode sources files from `$DIR/imports/` instead of remote URLs

### Docker Operations
- Compose files: `_deploy/compose.yaml` in each repository
- Start: `docker compose -f <file> up --build --detach`
- Check status: `docker container inspect -f '{{.State.Status}}' <container>`

## Configuration Format

- Primary: YAML (source.yaml, emma.yaml)
- Runtime: JSON (converted via Python yaml module)
- Access: `jq` for querying JSON data
