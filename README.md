# EMMA - Essential Machine Management Automation

## Overview
EMMA is a lightweight Bash-based automation script designed to simplify system setup tasks on Unix-based systems. It uses a configuration file to define the list of packages and other setup parameters.

## Usage

### Running the Script
You can run the script with or without specifying a configuration file:

1. **Using a Custom Configuration File:**
   ```bash
   ./install.sh my-config.yaml
   ```

2. **Using the Default Configuration File (`config.yaml`):**
   If no file is specified, the script will look for a file named `config.yaml` in the current directory:
   ```bash
   ./install.sh
   ```

3. **Error Handling:**
   If neither a custom file nor `config.yaml` exists, the script will exit with an error:
   ```
   Error: Configuration file 'config.yaml' not found.
   ```

### Configuration File (`config.yaml`)
The configuration file must be written in YAML format. It can include the following sections:

#### Example `config.yaml`:
```yaml
# List of packages to install
packages:
  - docker.io
  - git

# Additional configuration options (future use)
# pat: "your_personal_access_token"
# repos:
#   - "repo-name-1"
#   - "repo-name-2"
```

### Dependencies
The script requires the following tools:
- `curl` (for downloading additional scripts dynamically)
- `yq` (for parsing the YAML configuration file)

If `yq` is not installed, the script will automatically install it.

## Customization
- Extend the `config.yaml` file to include additional setup parameters such as personal access tokens, repository names, or other configuration options.
- Add your own setup tasks to the `install.sh` script where indicated.

## License
This project is licensed under the MIT License.
