# BASIC GUI FUNCTIONS

function printSectionHeadline {
  local text=$1
  local length=${#text}
  local end=$(((60 - "$length") / 2))
  local str="═"
  local range
  range=$(seq $end)
  printf "%s            " "$POWDER_BLUE"
  for i in $range; do echo -n "${str}"; done
  printf " %s " "$text"
  for i in $range; do echo -n "${str}"; done
  printf "%s\n" "$CLEAR"
}

function printSectionSubHeadline {
  local text=$1
  local length=${#text}
  local end=$(((60 - "$length") / 2))
  local str="-"
  local range
  range=$(seq $end)

  # printf "\033[1A"

  printf "\n%s            " "$POWDER_BLUE"
  for i in $range; do echo -n "${str}"; done
  printf " %s " "$text"
  for i in $range; do echo -n "${str}"; done
  printf "\n\n%s" "$CLEAR"
}

function printError {
    local errorText
    errorText="$1"

    local lines
    lines=$(wc -l <<< "${errorText}")

    if [ "$lines" -eq 0 ]; then
        printf "%s ⚡ %s%s\n" "$ORANGE" "$errorText" "$CLEAR"
    else
        printf "%s ⚡ %s%s%s\n" "$ORANGE" "$UNDERLINE" "ERROR MESSAGE:" "$CLEAR"
        while IFS= read -r line ; do
            printf "%s     %s\n" "$ORANGE" "$line";
        done <<< "$errorText"

        printf "%s\n"  "$CLEAR"
    fi
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