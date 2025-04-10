# Text Colors
# shellcheck disable=SC2034
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
ORANGE=$(tput setaf 202)
BRIGHT_WHITE=$(tput setaf 255)

# Background Colors
BG_WHITE=$(tput setab 7)

# Text Styles
BRIGHT=$(tput bold)
CLEAR=$(tput sgr0)
BOLD=$(tput bold)
REVERSE=$(tput rev)
UNDERLINE=$(tput smul)

# Line Length
LINE_LENGTH=80