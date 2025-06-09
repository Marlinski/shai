#!/bin/sh

tui_set_scheme() {
    scheme="${1:-professional_blue}"
    
    case "$scheme" in
        "professional_blue")
            TUI_HEADER="\033[1;36m"      # Bright Cyan
            TUI_SUCCESS="\033[1;32m"     # Bright Green
            TUI_ERROR="\033[1;31m"       # Bright Red
            TUI_WARNING="\033[1;33m"     # Bright Yellow
            TUI_TEXT="\033[0;37m"        # White
            TUI_ACCENT="\033[1;34m"      # Bright Blue
            TUI_DIM="\033[0;90m"         # Dark Gray
            ;;
        "hacker_green")
            TUI_HEADER="\033[1;32m"      # Bright Green
            TUI_SUCCESS="\033[0;32m"     # Green
            TUI_ERROR="\033[1;31m"       # Bright Red
            TUI_WARNING="\033[1;36m"     # Bright Cyan
            TUI_TEXT="\033[1;37m"        # Bright White
            TUI_ACCENT="\033[0;36m"      # Cyan
            TUI_DIM="\033[0;32m"         # Green
            ;;
        "subtle_modern")
            TUI_HEADER="\033[1;35m"      # Bright Magenta
            TUI_SUCCESS="\033[1;36m"     # Bright Cyan
            TUI_ERROR="\033[1;31m"       # Bright Red
            TUI_WARNING="\033[1;34m"     # Bright Blue
            TUI_TEXT="\033[0;37m"        # White
            TUI_ACCENT="\033[0;35m"      # Magenta
            TUI_DIM="\033[0;90m"         # Dark Gray
            ;;
    esac
    
    TUI_RESET="\033[0m"
    TUI_BOLD="\033[1m"
}

tui_set_scheme "professional_blue"

tui_clear_line() {
    printf "\033[1A\033[2K"
}

tui_print() {
    color="$1"
    shift
    case "$color" in
        "header")  printf "${TUI_HEADER}%s${TUI_RESET}" "$*" ;;
        "success") printf "${TUI_SUCCESS}%s${TUI_RESET}" "$*" ;;
        "error")   printf "${TUI_ERROR}%s${TUI_RESET}" "$*" ;;
        "warning") printf "${TUI_WARNING}%s${TUI_RESET}" "$*" ;;
        "text")    printf "${TUI_TEXT}%s${TUI_RESET}" "$*" ;;
        "accent")  printf "${TUI_ACCENT}%s${TUI_RESET}" "$*" ;;
        "dim")     printf "${TUI_DIM}%s${TUI_RESET}" "$*" ;;
        "bold")    printf "${TUI_BOLD}%s${TUI_RESET}" "$*" ;;
        *)         printf "%s" "$*" ;;
    esac
}

tui_println() {
    color="$1"
    shift
    tui_print "$color" "$*"
    printf "\n"
}

tui_status() {
    type="$1"
    message="$2"
    newline="${3:-true}"  # Default to true (print newline)
    
    case "$type" in
        "error")   symbol="⊗"; color1="error"; color2="error" ;;
        "success") symbol="✓"; color1="success"; color2="bold" ;;
        "info")    symbol="⊙"; color1="accent"; color2="dim" ;;
        "warning") symbol="⚠"; color1="warning"; color2="dim" ;;
        "working") symbol="⊙"; color1="accent"; color2="dim" ;;
        "none")    symbol="┊"; color1="dim"; color2="dim" ;;
        *)         symbol="•"; color1="text"; color2="dim" ;;
    esac
    
    tui_print "$color1" "$symbol"
    if [ "$newline" = "true" ]; then
        tui_println "$color2" " $message"
    else
        tui_print "$color2" " $message"
    fi
}

tui_actions() {
    first=true
    for action in "$@"; do
        if [ "$first" = "false" ]; then
            printf " • "
        fi
        tui_print "accent" "["
        printf "%s" "$action"
        tui_print "accent" "]"
        first=false
    done
    printf "\n"
}
