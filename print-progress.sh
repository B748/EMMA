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
