function prepareSystem {
    # CHECK IF A CONFIGURATION FILE IS PROVIDED AS AN ARGUMENT
    local CONFIG_FILE
    CONFIG_FILE="$1"

    printProgress "Reading configuration file" "$CYAN"
    if [ -z "$CONFIG_FILE" ]; then
        CONFIG_FILE="config.yaml"
    fi

    if [ ! -f "$DIR/$CONFIG_FILE" ]; then
        printResult 0 1
        printError "Configuration file \"$CONFIG_FILE\" not found."
        exit 1
    else
        # CREATES VARIABLES NAMED ACCORDING YAML, PREFIXED WITH "CONF_"
        eval "$(parse_yaml "$DIR/$CONFIG_FILE" "CONF_")"
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
        local PAT=$1
        local REPO_URL=$2
        local RESULT_TEXT

        local REPO_FILE_NAME
        REPO_FILE_NAME=$(eval basename "$REPO_URL")

        local REPO_NAME
        REPO_NAME=${REPO_FILE_NAME%.git}

        printSection "INSTALLING REPOSITORY \"$REPO_NAME\""

        # CLEANUP
        printProgress "Cleaning folders" "$CYAN"
        RESULT_TEXT=$(sudo rm -rf "${DIR:?}/$REPO_NAME" 2>&1) 1>/dev/null
        local RESULT=$?

        printResult 0 $RESULT

        if [ "$RESULT" -ne 0 ]; then
            printEmptyLine
            printError "$RESULT_TEXT"
            exit 1
        fi

        # REPO CLONING FROM GITHUB
        printProgress "Cloning repository" "$CYAN"

        RESULT_TEXT=$(git clone "https://${PAT}@${REPO_URL#https://}" "$DIR/$REPO_NAME/" 2>&1) 1>/dev/null
        local RESULT=$?

        printResult 0 $RESULT

        if [ "$RESULT" -ne 0 ]; then
            printEmptyLine
            printError "$RESULT_TEXT"
            exit 1
        fi

        # READING REPO'S EMMA-CONFIG-FILE
        printProgress "Reading config-file" "$CYAN"
        local REPO_CONFIG_FILE_NAME
        REPO_CONFIG_FILE_NAME=$DIR/$REPO_NAME/_deploy/config.yaml
        eval "$(parse_yaml "$REPO_CONFIG_FILE_NAME" "REPO_")"
        printResult 0 $?

        # INSTALLING REQUIRED DEPENDENCIES
        printStep "INSTALLING REQUIRED PACKAGES"

        for packageVarRef in $REPO_packages_; do
            packageName=${packageVarRef}
            installPackage "${!packageName}"
        done


        # RUNNING DOCKER COMPOSE
        local DOCKER_COMPOSE_FILE_NAME
        DOCKER_COMPOSE_FILE_NAME=$DIR/$REPO_NAME/_deploy/compose.yaml

        if [ -e "$DOCKER_COMPOSE_FILE_NAME" ]; then
            printStep "RUNNING DOCKER COMPOSE"

            printProgress "Checking Docker Compose version" "$CYAN"
            local DOCKER_COMPOSE_VERSION
            DOCKER_COMPOSE_VERSION=$(docker compose version)
            DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION##* }
            printResult 0 0 "$DOCKER_COMPOSE_VERSION"

            printProgress "Running Docker Compose" "$CYAN"
            RESULT_TEXT=$(sudo docker compose -f "$DOCKER_COMPOSE_FILE_NAME" up --build --detach http-server 2>&1) 1>/dev/null
            local RESULT=$?

            printResult 0 $RESULT

            if [ "$RESULT" -ne 0 ]; then
                printEmptyLine
                printError "$RESULT_TEXT"
                exit 1
            fi

            setSectionEnd
        else
            printProgress "Checking for Docker Installation Files" "$CYAN"
            printResult 0 0 "NONE"
        fi

    else
        printError "Repository not found."
    fi
}

function installPackage {
    local PACKAGE
    PACKAGE=$1

    printProgress "Installing \"$PACKAGE\"" "$CYAN"
    local RESULT_TEXT
    RESULT_TEXT=$(sudo apt-get install -y "$PACKAGE" 2>&1) 1>/dev/null
    local RESULT=$?

    printResult 0 $RESULT

    if [ "$RESULT" -ne 0 ]; then
      printEmptyLine
      printError "$RESULT_TEXT"
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
