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
        CONFIG_DATA=$(yamlToJSON "$configFileName" "")
        printResult 0 $?
    fi

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
        local GIT_VERSION
        GIT_VERSION=$(git -v)
        GIT_VERSION=${GIT_VERSION##* }
        printProgress "Git version" "$CYAN"
        printResult 0 0 "$GIT_VERSION"
    fi

    printStep "CREATING TWO-WAY COMMUNICATION BASE"

    # NOMENCLATURE:
    # DOCKER => CONTAINER = UPLINK ("TO SATELLITE")
    # CONTAINER => DOCKER = DOWNLINK ("FROM SATELLITE")
    local sendPipeName="docker-uplink"
    local receivePipeName="docker-downlink"
    local pipePath="$EMMA_DIR/pipes"
    local senderPipePath="$pipePath/$sendPipeName"
    local receiverPipePath="$pipePath/$receivePipeName"

    local receiverScriptName="downlink-processing.sh"
    local receiverScriptUrl="$EMMA_URL/host/$receiverScriptName"
    local receiverScriptPath="$EMMA_DIR/host/$receiverScriptName"

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
    crontab -l | grep $receiverScriptPath > /dev/null 2<&1 || (crontab -l 2>/dev/null; echo "@reboot $receiverScriptPath $receiverPipePath") | crontab -
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
        printStep "INSTALLING REQUIRED PACKAGES"

        for packageName in $requiredRepoPackages; do
            installPackage "$packageName"
        done

        # RUNNING PRE SCRIPTS
        printStep "RUNNING PRE-INSTALL SCRIPTS"

        for scriptName in $preRunScripts; do
            printProgress "Executing script \"$scriptName\"" "$CYAN"
            sudo chmod +x "$EMMA_DIR/dist-src/$repoName/_deploy/$scriptName"
            resultText=$(bash "$EMMA_DIR/dist-src/$repoName/_deploy/$scriptName")
            local result=$?

            printResult 0 $result

            if [ "$result" -ne 0 ]; then
                printEmptyLine
                printError "$resultText"
                exit 1
            fi
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
                printProgress "Executing script \"$scriptName\"" "$CYAN"
                printProgress "Executing script \"$scriptName\"" "$CYAN"
                sudo chmod +x "$EMMA_DIR/dist-src/$repoName/_deploy/$scriptName"
                bash "$EMMA_DIR/dist-src/$repoName/_deploy/$scriptName"
                printResult 0 $?
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

function installPackage {
    local PACKAGE
    PACKAGE=$1

    printProgress "Installing \"$PACKAGE\"" "$CYAN"
    local resultText
    resultText=$(sudo apt-get install -y "$PACKAGE" 2>&1) 1>/dev/null
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

function terminateScript {
    printf "%s 🔥 %s%s\n" "$RED" "INSTALLATION TERMINATED" "$CLEAR"
    kill -s TERM $TOP_PID
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
    json=$(python3 -c "import yaml;print(yaml.safe_load(open('$1'))$2)")
    json="${json//\'/\"}"
    json="${json//: None/: null}"
    echo "$json"
}

getJSONValue() {
    local selection=$1
    local json=$2
    local result
    result="$(jq -r "$selection" <<< "$json")"
    echo "$result"
}
