function getConfiguration {
  # CHECK IF A CONFIGURATION FILE IS PROVIDED AS AN ARGUMENT
  CONFIG_FILE="$1"

  printProgress " ★ Reading configuration file" "$CYAN"
  if [ -z "$CONFIG_FILE" ]; then
      CONFIG_FILE="config.yaml"
      # echo "No configuration file provided. Using default: $CONFIG_FILE"
  fi

  if [ ! -f "$CONFIG_FILE" ]; then
      printResult 0 1
      printError "Configuration file \"$CONFIG_FILE\" not found."
      exit 1
  fi

  printResult 0 0
}

function installRepo {
    if [ -n "$repoUrl" ] ; then
        local pat=$1
        local repoUrl=$2

        local repoFileName
        repoFileName=$(eval basename "$repoUrl")

        local repoName
        repoName=${repoFileName%.git}

        printSectionSubHeadline "Installing \"$repoName\""

        printProgress " ★ Cloning repository \"$repoFileName\"" "$CYAN"

        resultText=$(git clone "https://${pat}@${repoUrl#https://}" 2>&1) 1>/dev/null
        result=$?

        printResult 0 $result

        if [ "$result" -ne 0 ]; then
            printError "$resultText"
        fi

        # CREATES VARIABLES NAMED ACC TO YAML, PREFIXED WITH "CONF_"
#            eval "$(parse_yaml "$CONFIG_FILE" "CONF_")"
    else
        printError "Repository not found."
    fi

}