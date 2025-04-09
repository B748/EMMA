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