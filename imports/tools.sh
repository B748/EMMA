function prepareSystem {
    # CHECK IF A CONFIGURATION FILE IS PROVIDED AS AN ARGUMENT
    local CONFIG_FILE
    CONFIG_FILE="$1"

    printProgress "Reading configuration file" "$CYAN"
    if [ -z "$CONFIG_FILE" ]; then
        CONFIG_FILE="$DIR/config.yaml"
    fi

    if [ ! -f "$CONFIG_FILE" ]; then
        printResult 0 1
        printError "Configuration file \"$CONFIG_FILE\" not found."
        exit 1
    else
        # CREATES VARIABLES NAMED ACCORDING YAML, PREFIXED WITH "CONF_"
        eval "$(parse_yaml "$CONFIG_FILE" "CONF_")"
        printResult 0 0
    fi

    printProgress "Updating package list" "$CYAN"
    sudo apt-get update >/dev/null 2>&1
    printResult 0 $?

    printProgress "Updating installed packages" "$CYAN"
    sudo apt-get -y upgrade >/dev/null 2>&1
    printResult 0 $?

    # ENSURE GIT IS INSTALLED
    if ! command -v git >/dev/null 2>&1; then
        printProgress "Installing Git" "$CYAN"
        sudo apt-get install -y git >/dev/null 2>&1
        printResult 0 $?
    else
        local GIT_VERSION
        GIT_VERSION=$(git -v)
        GIT_VERSION=${GIT_VERSION##* }
        printProgress "Checking Git version" "$CYAN"
        printResult 0 0 "$GIT_VERSION"
    fi
}

function installRepo {
    if [ -n "$2" ] ; then
        local pat=$1
        local repoUrl=$2
        local resultText

        local repoFileName
        repoFileName=$(eval basename "$repoUrl")

        local repoName
        repoName=${repoFileName%.git}

        printSection "INSTALLING REPOSITORY \"$repoName\""

        # CLEANUP
        printProgress "Cleaning folders" "$CYAN"
        resultText=$(sudo rm -rf "${DIR:?}/$repoName" 2>&1) 1>/dev/null
        local result=$?

        printResult 0 $result

        if [ "$result" -ne 0 ]; then
            printEmptyLine
            printError "$resultText"
            exit 1
        fi

        # REPO CLONING FROM GITHUB
        printProgress "Cloning repository" "$CYAN"

        resultText=$(git clone "https://${pat}@${repoUrl#https://}" "$DIR/$repoName/" 2>&1) 1>/dev/null
        local result=$?

        printResult 0 $result

        if [ "$result" -ne 0 ]; then
            printEmptyLine
            printError "$resultText"
            exit 1
        fi

        # READING REPO'S EMMA-CONFIG-FILE
        printProgress "Reading config-file" "$CYAN"
        local repoConfigFileName
        repoConfigFileName=$DIR/$repoName/_deploy/config.yaml
        eval "$(parse_yaml "$repoConfigFileName" "REPO_")"
        printResult 0 $?

        # INSTALLING REQUIRED DEPENDENCIES
        printStep "INSTALLING REQUIRED PACKAGES"

        for packageVarRef in $REPO_packages_; do
            packageName=${packageVarRef}
            installPackage "${!packageName}"
        done

        # RUNNING DOCKER COMPOSE
        local dockerComposeFileName
        dockerComposeFileName=$DIR/$repoName/_deploy/compose.yaml

        if [ -e "$dockerComposeFileName" ]; then
            runDockerCompose "$dockerComposeFileName"

            printEmptyLine
            printSection "CHECKING DOCKER CONTAINER STATUS"

            # READING DOCKER COMPOSE
            printProgress "Reading docker-compose file" "$CYAN"
            local dockerComposeFileName
            dockerComposeFileName=$DIR/$repoName/_deploy/compose.yaml
            tmp=$(yaml "$dockerComposeFileName" "")
            printResult 0 $?

            names="$(jq '.services | keys[]' <<< "$tmp")"
            for serviceName in $names; do
                checkDockerContainerStatus "$serviceName"
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
    printProgress "$dockerContainer status"
    if [ "$(sudo docker container inspect -f '{{.State.Status}}' "$dockerContainer")" = "running" ]; then
        printResult 0 0 "RUNNING"
    else
        printResult 0 1 "" "STOPPED"
    fi
}

yaml() {
    local json
    json=$(python3 -c "import yaml;print(yaml.safe_load(open('$1'))$2)")
    json="${json//\'/\"}"
    json="${json//: None/: null}"
    echo "$json"
}