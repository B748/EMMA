# BASIC GUI FUNCTIONS

function printHeader {
    local text=$1
    local margin=5

    # see https://www.w3.org/TR/xml-entity-names/025.html
    local hLine="═"
    local vLine="║"
    local cornerTL="╔"
    local cornerTR="╗"
    local cornerBL="╚"
    local cornerBR="╝"

#    local hLine="┉"
#    local vLine="┊"
#    local cornerTL="╭"
#    local cornerTR="╮"
#    local cornerBL="╰"
#    local cornerBR="╯"

#    local hLine="═"
#    local vLine="│"
#    local cornerTL="╒"
#    local cornerTR="╕"
#    local cornerBL="╘"
#    local cornerBR="╛"


    printf ".%.0s" $(seq $LINE_LENGTH)
    printf "\n\n"

    printf " %.0s" $(seq $margin);
    printf "%s$cornerTL" "$POWDER_BLUE"
    printf "$hLine%.0s" $(seq $((LINE_LENGTH - 2 - 2 * margin)));
    printf "$cornerTR\n"

    IFS=$'\n'
    for line in $(printf "$text"); do
        local length=${#line}
        local leftCount=$(((LINE_LENGTH - 2 * margin - length) / 2))
        local rightCount=$((LINE_LENGTH - 2 * margin - 4 - leftCount - length))

        printf " %.0s" $(seq $margin);
        printf "$vLine";
        printf " %.0s" $(seq $leftCount);
        printf " %s%s%s%s " "$BOLD" "$line" "$CLEAR" "$POWDER_BLUE";
        printf " %.0s" $(seq $rightCount);
        printf "$vLine\n"
    done
    IFS=$' \n\t'

    printf " %.0s" $(seq $margin);
    printf "$cornerBL"
    printf "$hLine%.0s" $(seq $((LINE_LENGTH - 2 - 2 * margin)));
    printf "$cornerBR%s\n\n" "$CLEAR"
}

function printSectionSubHeadline {
  local text=$1
  local length=${#text}
  local end=$(((60 - "$length") / 2))
  local str="-"
  local range
  range=$(seq $end)

  printf "\n%s            " "$POWDER_BLUE"
  for i in $range; do echo -n "${str}"; done
  printf " %s " "$text"
  for i in $range; do echo -n "${str}"; done
  printf "\n\n%s" "$CLEAR"
}

function printEmptyLine {
    local lines
    lines=$1
    lines=${lines:=1}

    for (( c =1; c<=lines; c++ )) do printf "\n"; done
}

function printSection {
    local stepText
    stepText="$1"

    INDENTATION=${INDENTATION:0}+5

    printf "%s ★ %s%s:%s\n" "$BLUE" "$UNDERLINE" "$stepText" "$CLEAR"
}

function setSectionEnd {
    INDENTATION=${INDENTATION:0}-5
}

function printStep {
    local stepText
    stepText="$1"

    printf "%s" "$BRIGHT_WHITE"
    printf " %.0s" $(seq $((INDENTATION - 1)))
    printf "%s%s:%s\n" "$UNDERLINE" "$stepText" "$CLEAR"
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
    start=$((start + INDENTATION))
    local fillerStr="."

    local range
    range=$(seq "$start" "$LINE_LENGTH")

    printf " %.0s" $(seq $((INDENTATION - 0)))
    printf "%s%s" "$CYAN" "$text"
    printf "$fillerStr%.0s" $(seq $((LINE_LENGTH - start - 1)))
}

function printResult {
    local okVal=$1
    local returnVal=$2

    local okReturn=$3
    okReturn=${okReturn:-"DONE"}
    okReturnLength=${#okReturn}

    local failReturn=$4
    failReturn=${failReturn:-"FAIL"}
    failReturnLength=${#failReturn}

    if [ "$returnVal" -eq "$okVal" ]; then
        for i in $(seq $((okReturnLength - 1))); do tput cub1; done
        printf "%s%s%s\n" "$GREEN" "$okReturn" "$CLEAR"
    else
        for i in $(seq $((failReturnLength - 1))); do tput cub1; done
        printf "%s%s%s\n" "$RED" "$failReturn" "$CLEAR"
    fi

    return "$returnVal"
}