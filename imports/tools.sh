# FUNCTIONS LIBRARY

function validateDependencies {
    printStep "VALIDATING REQUIRED TOOLS"
    
    local missingTools=()
    
    # Check curl
    if ! command -v curl >/dev/null 2>&1; then
        missingTools+=("curl")
    fi
    
    # Check jq
    if ! command -v jq >/dev/null 2>&1; then
        missingTools+=("jq")
    fi
    
    # Check python3
    if ! command -v python3 >/dev/null 2>&1; then
        missingTools+=("python3")
    else
        # Check for yaml module
        if ! python3 -c "import yaml" 2>/dev/null; then
            missingTools+=("python3-yaml")
        fi
    fi
    
    # Check docker
    if ! command -v docker >/dev/null 2>&1; then
        missingTools+=("docker")
    fi
    
    if [ ${#missingTools[@]} -gt 0 ]; then
        printProgress "Required tools check" "$CYAN"
        printResult 0 1
        printError "Missing required tools: ${missingTools[*]}"
        printError "Please install missing dependencies and try again."
        exit 1
    else
        printProgress "Required tools check" "$CYAN"
        printResult 0 0
    fi
}

function prepareSystem {
    # CHECK IF A CONFIGURATION FILE IS PROVIDED AS AN ARGUMENT
    local configFileName
    configFileName="$1"

    printProgress "Read configuration file" "$CYAN"
    if [ -z "$configFileName" ]; then
        configFileName="$DIR/source.yaml"
    fi

    if [ ! -f "$configFileName" ]; then
        printResult 0 1
        printError "Configuration file \"$configFileName\" not found."
        exit 1
    else
        # READING CONFIG FILE
        # shellcheck disable=SC2034
        CONFIG_DATA=$(yamlToJSON "$configFileName" "")
        printResult 0 $?
    fi

    validateDependencies

    printProgress "Update package list" "$CYAN"
    sudo apt-get update >/dev/null 2>&1
    printResult 0 $?

    printProgress "Update installed packages" "$CYAN"
    sudo apt-get -y upgrade >/dev/null 2>&1
    printResult 0 $?

    # ENSURE GIT IS INSTALLED
    if ! command -v git >/dev/null 2>&1; then
        printProgress "Install Git" "$CYAN"
        sudo apt-get install -y git >/dev/null 2>&1
        printResult 0 $?
    else
        local gitVersion
        gitVersion=$(git --version)
        gitVersion=${gitVersion##* }
        printProgress "Git version" "$CYAN"
        printResult 0 0 "$gitVersion"
    fi

    createPipeSystem
}

function createPipeSystem {
        printStep "CREATING TWO-WAY COMMUNICATION BASE"

        # NOMENCLATURE:
        # DOCKER => CONTAINER = UPLINK ("TO SATELLITE")
        # CONTAINER => DOCKER = DOWNLINK ("FROM SATELLITE")
        local sendPipeName="docker-uplink"
        local receivePipeName="docker-downlink"

        local pipePath="$EMMA_DIR/pipes"
        local receiverScriptName="downlink-processing.sh"

        local receiverScriptUrl="$EMMA_URL/host/$receiverScriptName"
        local receiverScriptPath="$EMMA_DIR/host/$receiverScriptName"
        local receiverPipePath="$pipePath/$receivePipeName"

        local senderPipePath="$pipePath/$sendPipeName"

        # CREATE/CHECK PIPES
        if [ ! -d "$EMMA_DIR" ]; then
            printProgress "Create EMMA main directory" "$CYAN"
            sudo mkdir "$EMMA_DIR" >/dev/null 2>&1
            sudo chown -R "$(id -u)":"$(id -g)" "$EMMA_DIR"
            printResult 0 $?
        fi

        if [ ! -p "$receiverPipePath" ]; then
            printProgress "Create receiver-pipe" "$CYAN"
            mkdir -p "$pipePath"
            mkfifo "$receiverPipePath" >/dev/null 2>&1
            printResult 0 $?
        fi

        if [ ! -p "$senderPipePath" ]; then
            printProgress "Create sender-pipe" "$CYAN"
            mkfifo "$senderPipePath" >/dev/null 2>&1
            printResult 0 $?
        fi

        printProgress "Download processing-script" "$CYAN"
        curl -sSL "$receiverScriptUrl" --create-dirs -o "$receiverScriptPath" >/dev/null 2>&1
        printResult 0 $?

        printProgress "Make processing-script executable" "$CYAN"
        sudo chmod +x "$receiverScriptPath" >/dev/null 2>&1
        printResult 0 $?

        printProgress "Make processing-script reboot-proof" "$CYAN"
        crontab -l | grep "$receiverScriptPath" > /dev/null 2<&1 || (crontab -l 2>/dev/null; echo "@reboot $receiverScriptPath $receiverPipePath") | crontab -
        printResult 0 $?

        printProgress "Stop running processing-script(s)" "$CYAN"
        sudo pkill $receivePipeName
        printResult 0 $? "" "NONE FOUND"

        printProgress "Run processing-script" "$CYAN"
        nohup "$receiverScriptPath" "$receiverPipePath" &> /dev/null &
        printResult 0 $?
}

function installRepo {
    if [ -n "$2" ] ; then
        local pat=$1
        local repoUrl=$2
        local resultText

        local repoFileName
        repoFileName=$(eval basename "$repoUrl")

        local repoName=${repoFileName%.git}

        printSection "INSTALLING REPOSITORY \"$repoName\""

        # CLEANUP
        printProgress "Cleaning folders" "$CYAN"
        resultText=$(sudo rm -rf "$EMMA_DIR/dist-src/$repoName/" 2>&1) 1>/dev/null
        local result=$?

        printResult 0 $result

        if [ "$result" -ne 0 ]; then
            printEmptyLine
            printError "$resultText"
            exit 1
        fi

        # REPO CLONING FROM GITHUB
        local url=https://$pat@github.com/$repoUrl

        printProgress "Cloning repository" "$CYAN"
        resultText=$(git clone "$url" "$EMMA_DIR/dist-src/$repoName/" 2>&1) 1>/dev/null
        local result=$?

        printResult 0 $result

        if [ "$result" -ne 0 ]; then
            printEmptyLine
            printError "$resultText"
            exit 1
        fi

        # READING REPO'S EMMA-CONFIG-FILE
        local repoConfigData
        local requiredRepoPackages
        local preRunScripts
        local postRunScripts

        printProgress "Reading config-file" "$CYAN"
        local repoConfigFileName=$EMMA_DIR/dist-src/$repoName/_deploy/emma.yaml
        repoConfigData="$(yamlToJSON "$repoConfigFileName")"
        requiredRepoPackages=$(getJSONValue ".packages  | values[]" "$repoConfigData")
        preRunScripts=$(getJSONValue ".scripts.pre  | values[]" "$repoConfigData")
        postRunScripts=$(getJSONValue ".scripts.post  | values[]" "$repoConfigData")
        printResult 0 $?

        # INSTALLING REQUIRED DEPENDENCIES
        printStep "INSTALLING REQUIRED packageS"

        for packageName in $requiredRepoPackages; do
            installPackage "$packageName"
        done

        # RUNNING PRE SCRIPTS
        printStep "RUNNING PRE-INSTALL SCRIPTS"

        for scriptName in $preRunScripts; do
            runScript "$EMMA_DIR/dist-src/$repoName/_deploy/$scriptName"
        done

        # RUNNING DOCKER COMPOSE
        local dockerComposeFileName=$EMMA_DIR/dist-src/$repoName/_deploy/compose.yaml

        if [ -e "$dockerComposeFileName" ]; then
            runDockerCompose "$dockerComposeFileName"

            setSectionEnd
            printEmptyLine

            printSection "CHECKING SETUP"

            # READING DOCKER COMPOSE
            printProgress "Reading docker-compose file" "$CYAN"
            local dockerComposeFileName=$EMMA_DIR/dist-src/$repoName/_deploy/compose.yaml
            tmp=$(yamlToJSON "$dockerComposeFileName" "")
            printResult 0 $?

            printStep "CONTAINER STATUS"

            names="$(jq '.services | keys[]' <<< "$tmp")"
            for serviceName in $names; do
                checkDockerContainerStatus "$serviceName"
            done

            # RUNNING POST SCRIPTS
            printStep "RUNNING POST-INSTALL SCRIPTS"

            for scriptName in $postRunScripts; do
                runScript "$EMMA_DIR/dist-src/$repoName/_deploy/$scriptName"
            done
        else
            printProgress "Checking for Docker Installation Files" "$CYAN"
            printResult 0 0 "NONE"
        fi

        setSectionEnd

    else
        printError "Repository not found."
    fi
}

function runScript {
    local scriptPath=$1

    printProgress "Executing script \"$(basename "$scriptPath" .sh)\"" "$CYAN"
    sudo chmod +x "$scriptPath"
    resultText=$(bash "$scriptPath" 2>&1) 1>/dev/null
    local result=$?

    printResult 0 $result

    if [ "$result" -ne 0 ]; then
        printEmptyLine
        printError "$resultText"
        exit 1
    fi
}

function installPackage {
    local package
    package=$1

    printProgress "Installing \"$package\"" "$CYAN"
    local resultText
    resultText=$(sudo apt-get install -y "$package" 2>&1) 1>/dev/null
    local result=$?

    printResult 0 $result

    if [ "$result" -ne 0 ]; then
      printEmptyLine
      printError "$resultText"
      exit 1
    fi
}

function listPackages {
    for pkg in $(apt list --upgradable 2>/dev/null | awk -F/ 'NR>1 {print $1}'); do
        echo "name: $pkg"
    done
}

function runDockerCompose {
    local dockerComposeFileName=$1

    printStep "RUNNING DOCKER COMPOSE"

    printProgress "Checking Docker Compose version" "$CYAN"
    local dockerComposeVersion
    dockerComposeVersion=$(docker compose version)
    dockerComposeVersion=${dockerComposeVersion##* }
    printResult 0 0 "$dockerComposeVersion"

    printProgress "Running Docker Compose" "$CYAN"
    resultText=$(sudo docker compose -f "$dockerComposeFileName" up --build --detach 2>&1) 1>/dev/null
    local result=$?

    printResult 0 $result

    if [ "$result" -ne 0 ]; then
        printEmptyLine
        printError "$resultText"
        exit 1
    fi
}

function checkDockerContainerStatus {
    local dockerContainer=$1
    dockerContainer="${dockerContainer//\"/}"
    printProgress "$dockerContainer"
    if [ "$(sudo docker container inspect -f '{{.State.Status}}' "$dockerContainer")" = "running" ]; then
        printResult 0 0 "RUNNING"
    else
        printResult 0 1 "" "STOPPED"
    fi
}

yamlToJSON() {
    local json
    json=$(python3 -c "import yaml;print(yaml.safe_load(open('$1'))$2)" 2>&1)
    local result=$?
    
    if [ $result -ne 0 ]; then
        echo "ERROR: Failed to parse YAML file '$1': $json" >&2
        return 1
    fi
    
    json="${json//\'/\"}"
    json="${json//: None/: null}"
    echo "$json"
    return 0
}

getJSONValue() {
    local selection=$1
    local json=$2
    local result
    result="$(jq -r "$selection" <<< "$json" 2>&1)"
    local exitCode=$?
    
    if [ $exitCode -ne 0 ]; then
        echo "ERROR: Failed to parse JSON with selector '$selection': $result" >&2
        return 1
    fi
    
    echo "$result"
    return 0
}
