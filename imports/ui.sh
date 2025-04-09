# BASIC GUI FUNCTIONS

function printSectionHeadline {
  local text=$1
  local length=${#text}
  local end=$(((38 - "$length") / 2))
  local str="═"
  local range
  range=$(seq $end)
  printf "\n\n%s            " "$LIME_YELLOW"
  for i in $range; do echo -n "${str}"; done
  printf " %s " "$text"
  for i in $range; do echo -n "${str}"; done
  printf "\n\n%s" "$CLEAR"
}

function printSectionSubHeadline {
  local text=$1
  local length=${#text}
  local end=$(((24 - "$length") / 2))
  local str="-"
  local range
  range=$(seq $end)

  printf "\033[1A"

  printf "%s            " "$LIME_YELLOW"
  for i in $range; do echo -n "${str}"; done
  printf " %s " "$text"
  for i in $range; do echo -n "${str}"; done
  printf "\n\n%s" "$CLEAR"
}

function printError {
  printf "\n%s ⚡ %s%s\n" "$ORANGE" "$1" "$CLEAR"
}

function printProgress {
  local text=$1
  local start=${#text}
  local end=60
  local str="."
  local range
  range=$(seq "$start" $end)
  printf "%s%s" "$2" "$text"
  for i in $range; do echo -n "${str}"; done
}

function printResult {
  local okVal=$1
  local returnVal=$2
  local okReturn=$3
  local failReturn=$4

  if [ "$returnVal" -eq "$okVal" ]; then
    printf "%s%s%s\n" "$GREEN" "${okReturn:-"DONE"}" "$CLEAR"
  else
    printf "%s%s%s\n" "$RED" "${failReturn:-"FAIL"}" "$CLEAR"
  fi

  return "$returnVal"
}