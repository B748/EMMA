#[[file:general.md]]

# Project Structure

## Directory Layout

```
/
├── install.sh                    # Main entry point
├── imports/                      # Reusable function libraries
│   ├── constants.sh             # Color codes, text styles, line length
│   ├── tools.sh                 # Core functions (install, deploy, pipes)
│   └── ui.sh                    # Terminal UI functions (print*, progress)
├── host/                        # Host-side processing
│   └── downlink-processing.sh   # Processes container commands
├── source.yaml                  # User configuration (gitignored)
└── .kiro/steering/              # AI assistant guidance
```

## Runtime Structure (Created by EMMA)

```
/opt/emma/
├── pipes/                       # Named pipes for communication
│   ├── docker-downlink         # Container → Host
│   └── docker-uplink           # Host → Container
├── host/                       # Host scripts
│   └── downlink-processing.sh
└── dist-src/                   # Cloned repositories
    └── <repo-name>/
        └── _deploy/
            ├── emma.yaml       # Repo-specific config
            ├── compose.yaml    # Docker Compose file
            └── *.sh            # Pre/post install scripts
```

## Module Organization

### imports/constants.sh
- Terminal color definitions (tput-based)
- Text style constants (BOLD, UNDERLINE, CLEAR)
- Global constants (LINE_LENGTH=80)

### imports/tools.sh
- `prepareSystem()` - Config reading, apt updates, Git check
- `createPipeSystem()` - Named pipe setup, cron job creation
- `installRepo()` - Clone, configure, deploy repositories
- `runDockerCompose()` - Container orchestration
- `yamlToJSON()` - Python-based YAML parser
- `getJSONValue()` - jq wrapper for JSON queries

### imports/ui.sh
- `printHeader()` - ASCII box headers
- `printSection()` - Section markers with indentation
- `printProgress()` - Dotted progress lines
- `printResult()` - DONE/FAIL status indicators
- `printError()` - Formatted error messages

### host/downlink-processing.sh
- Infinite loop reading from downlink pipe
- Regex-based command validation
- Whitelisted commands: `update`, `fetch v*`, `check-update`, `set-pat`
- Logs to `/opt/emma/pipes/downlink.log`

## Configuration Files

### source.yaml (User-provided)
```yaml
pat: "github_token"
repos:
  - "owner/repo-name"
```

### emma.yaml (Per-repository)
```yaml
packages: [list]
scripts:
  pre: [list]
  post: [list]
```

## Coding Conventions

- Functions use camelCase
- Variables use snake_case
- Global constants in UPPER_CASE
- shellcheck directives for known exceptions
- Error handling: exit 1 on failures
- Output redirection: `>/dev/null 2>&1` for silent operations
- Result capture: `resultText=$(command 2>&1) 1>/dev/null`
