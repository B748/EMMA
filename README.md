# EMMA - Essential Machine Management Automation

## Overview
EMMA is a lightweight Bash-based automation script designed to simplify system setup tasks on Unix-based systems. It uses a YAML configuration file to define the list of packages, a personal access token (PAT), and private repository URLs for cloning.

## Usage

### Running the Script
You can run the script with or without specifying a configuration file:

**One-liner Execution (Optional Config File):**
   You can execute the script directly from the repository using `curl`. Optionally, specify a custom configuration file name:
   ```bash
   curl -sSL https://raw.githubusercontent.com/B748/EMMA/main/install.sh | bash -s -- path/to/my-config.yaml
   ```
   If no custom file is specified, the script will default to `config.yaml`:
   ```bash
   curl -sSL https://raw.githubusercontent.com/B748/EMMA/main/install.sh | bash
   ```

### Configuration File (`source.yaml`)
The configuration file must be written in YAML format. It can include the following sections:

#### Example `source.yaml`:
```yaml
# Personal Access Token (PAT) for accessing private repositories
pat: "your_personal_access_token_here"

# Private repository URLs to clone
repos:
  - "https://github.com/example/private-repo.git"
```

### How the Script Uses `source.yaml`
1. **Install Packages**:
   The script reads the `packages` section and installs the listed packages using `apt-get`.

2. **Clone Private Repositories**:
   - The script uses the `pat` (Personal Access Token) from the configuration file to authenticate and clone private repositories listed in the `repos` section.
   - For example, the repository URL:
     ```
     https://github.com/example/private-repo.git
     ```
     will be converted to:
     ```
     https://your_personal_access_token_here@github.com/example/private-repo.git
     ```
     This allows the script to authenticate and clone the repository.

### Dependencies
The script requires the following tools:
- `curl` (for downloading additional scripts dynamically)
- `git` (for cloning repositories)

If any dependencies are missing, the script will attempt to install them automatically.

### Customization
- Extend the `config.yaml` file to include additional setup parameters such as personal access tokens, repository names, or other configuration options.
- Add your own setup tasks to the `install.sh` script where indicated.

## License
This project is licensed under the MIT License.

## Acknowledgements
https://stackoverflow.com/questions/32163955/how-to-run-shell-script-on-host-from-docker-container
