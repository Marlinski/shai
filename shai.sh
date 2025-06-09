#!/bin/bash


# =============================================================================
# From: src/shai.sh
# =============================================================================


# Universal way to get script directory (works in bash and zsh)
if [[ -n "$BASH_VERSION" ]]; then
    SHAI_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "$ZSH_VERSION" ]]; then
    SHAI_SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
    SHAI_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

export SHAI_MAIN_PATH="$SHAI_SCRIPT_DIR/shai.sh"

if [[ "${0##*/}" == "shai.sh" ]] && [[ -z "$PS1" ]]; then
    echo "This script must be sourced"
    echo "Usage: source shai.sh"
    exit 1
fi


# =============================================================================
# From: src/config.sh.example
# =============================================================================


export OPENAI_BASE_URL=""
export OPENAI_API_KEY=""
export OPENAI_MODEL=""
export SHAI_LOG_LEVEL=3


# =============================================================================
# From: src/tui.sh
# =============================================================================


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

# =============================================================================
# From: src/logging.sh
# =============================================================================


_shai_debug_log="/tmp/shai_debug_$$.log"

export LOG_GRAY='\033[90m'
export LOG_RED='\033[0;31m'
export LOG_GREEN='\033[0;32m'
export LOG_YELLOW='\033[1;33m'
export LOG_BLUE='\033[0;34m'
export LOG_NC='\033[0m' 

SHAI_LOG_LEVEL=${SHAI_LOG_LEVEL:3}

log_debug() {
    if [[ $SHAI_LOG_LEVEL -le 0 ]]; then
        while IFS= read -r line; do
            local clean_msg=$(sed 's/\x1b\[[0-9;]*m//g' <<< "$line")
            [[ -z "$clean_msg" ]] && continue 
            echo -e "${LOG_GRAY}$clean_msg${LOG_NC}" >> "$_shai_debug_log"
        done <<< "$*"
    fi
}

log_info() {
    if [[ $SHAI_LOG_LEVEL -le 1 ]]; then
        while IFS= read -r line; do
            local clean_msg=$(sed 's/\x1b\[[0-9;]*m//g' <<< "$line")
            [[ -z "$clean_msg" ]] && continue  
            echo -e "${LOG_GRAY}$clean_msg${LOG_NC}" >> "$_shai_debug_log"
        done <<< "$*"
    fi
}

log_warn() {
    if [[ $SHAI_LOG_LEVEL -le 2 ]]; then
        while IFS= read -r line; do
            local clean_msg=$(sed 's/\x1b\[[0-9;]*m//g' <<< "$line")
            [[ -z "$clean_msg" ]] && continue 
            echo -e "${LOG_GRAY}$clean_msg${LOG_NC}" >> "$_shai_debug_log"
        done <<< "$*"
    fi
}

log_error() {
    if [[ $SHAI_LOG_LEVEL -le 3 ]]; then
        while IFS= read -r line; do
            local clean_msg=$(sed 's/\x1b\[[0-9;]*m//g' <<< "$line")
            [[ -z "$clean_msg" ]] && continue 
            echo -e "${LOG_GRAY}$clean_msg${LOG_NC}" >> "$_shai_debug_log"
        done <<< "$*"
    fi
}

trap 'rm -f "$_shai_debug_log"' EXIT
# =============================================================================
# From: src/context.sh
# =============================================================================


_get_last_command() {
    local num_commands="${1:-1}" 
    local commands=""
    
    if [[ -n "$ZSH_VERSION" ]]; then
        commands=$(fc -ln -${num_commands} 2>/dev/null | sed 's/^[[:space:]]*//')
    elif [[ -n "$BASH_VERSION" ]]; then
        commands=$(history ${num_commands} 2>/dev/null | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
    elif command -v fc >/dev/null 2>&1; then
        commands=$(fc -ln -${num_commands} 2>/dev/null | sed 's/^[[:space:]]*//')
    elif command -v history >/dev/null 2>&1; then
        commands=$(history ${num_commands} 2>/dev/null | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
    else
        return 1
    fi
    
    echo "$commands"
}


_get_system_context() {
    local sections=("$@")
    local context=""
    
    # If no sections specified, include all
    if [[ ${#sections[@]} -eq 0 ]]; then
        sections=("os" "shell" "user" "privileges" "dir" "env" "git" "versions" "disk")
    fi
    
    # Helper function to check if section is requested
    _should_include() {
        local section="$1"
        for s in "${sections[@]}"; do
            [[ "$s" == "$section" ]] && return 0
        done
        return 1
    }
    
    # System & OS
    if _should_include "os"; then
        if [[ -f /etc/os-release ]]; then
            local os_info=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d'"' -f2)
            context+="OS: ${os_info}\n"
        elif command -v uname >/dev/null 2>&1; then
            context+="OS: $(uname -s) $(uname -r)\n"
        fi
    fi
    
    # Shell
    if _should_include "shell"; then
        if [[ -n "$BASH_VERSION" ]]; then
            context+="Shell: bash $BASH_VERSION\n"
        elif [[ -n "$ZSH_VERSION" ]]; then
            context+="Shell: zsh $ZSH_VERSION\n"
        else
            context+="Shell: $0\n"
        fi
    fi

    # Current directory and user
    if _should_include "user"; then
        context+="Current User: $(whoami)\n"
        context+="Pwd: $(pwd)\n"
    fi

    # Shell
    if _should_include "dir"; then
        if command -v ls >/dev/null 2>&1; then
            context+="Current Directory: $(ls -la 2>/dev/null || echo "Could not list directory")\n"
        else
            context+="Current Directory: Could not list directory\n"
        fi
    fi

    # User permissions (check if root/sudo)
    if _should_include "privileges"; then
        if [[ $EUID -eq 0 ]]; then
            context+="Privileges: root\n"
        elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
            context+="Privileges: sudo available\n"
        else
            context+="Privileges: regular user\n"
        fi
    fi

    # Key environment variables (truncated)
    if _should_include "env"; then
        if [[ -n "$PATH" ]]; then
            local path_value="$PATH"
            if [[ ${#path_value} -gt 200 ]]; then
                path_value="${path_value:0:197}..."
            fi
            context+="PATH: $path_value\n"
        fi
        [[ -n "$HOME" ]] && context+="HOME: $HOME\n"
        [[ -n "$LANG" ]] && context+="LANG: $LANG\n"
        [[ -n "$TERM" ]] && context+="TERM: $TERM\n"
    fi

    # Git context (if in a git repo)
    if _should_include "git"; then
        if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            local git_branch=$(git branch --show-current 2>/dev/null || echo "detached")
            local git_status=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
            context+="Git: branch '$git_branch'"
            [[ $git_status -gt 0 ]] && context+=" (${git_status} changes)"
            context+="\n"
        fi
    fi

    # Python/Node/etc versions (if available and commonly used)
    if _should_include "versions"; then
        for cmd in python3 python node npm; do
            if command -v "$cmd" >/dev/null 2>&1; then
                local version=$($cmd --version 2>/dev/null | head -1)
                [[ -n "$version" ]] && context+="$cmd: $version\n"
            fi
        done
    fi

    # Disk space of current directory (useful for space-related errors)
    if _should_include "disk"; then
        if command -v df >/dev/null 2>&1; then
            local disk_info=$(df -h . 2>/dev/null | tail -1 | awk '{print $4 " available (" $5 " used)"}')
            [[ -n "$disk_info" ]] && context+="Disk: $disk_info\n"
        fi
    fi

    echo -e "$context"
}
# =============================================================================
# From: src/llm_prompt.sh
# =============================================================================


# =============================================================================
# From: src/llm.sh
# =============================================================================



_get_llm_system_prompt() {
    cat << 'EOF'
You are a helpful command line assistant that fixes broken shell commands. 
When a user's command fails, analyze the situation and provide your response in this exact format (do not actually enumerate):
1. First, provide a brief explanation of what went wrong and how to fix it
2. Add this exact separator on its own line "==="
2. Provides the corrected command without any quotes

Guidelines:
- Use the provided system context, recent output, and command history to understand the situation
- Look for common issues like typos in filenames, missing flags, wrong paths, permission issues
- Keep explanations concise but helpful
- Sometime the user would directly provide instruction, in that case try to make the command that fulfill the user's query
- Ensure the fixed command is safe and appropriate for the user's environment.

Example:
The error occurred because the filename was misspelled. You have "README.md" but typed "READNE.md".
===
ls README.md
EOF
}


fix() {
    local failed_command="$1"
    local exit_code="$2"
    local recent_output="$3"
    local last_n_cmds="$(_get_last_command 10)"
    local context="$(_get_system_context "os" "shell" "user" "dir" "env" "git")"

    log_debug "[fix] failed_command=$failed_command"
    log_debug "[fix] exit_code=$exit_code"
    log_debug "[fix] last_n_cmds=$last_n_cmds"
    log_debug "[fix] context=$context"
    log_debug "[fix] recent_output=$recent_output"

    # Build the user message with all context
    local user_message=""

    user_message+="SYSTEM CONTEXT:\n$context"

    if [[ -n "$last_n_cmds" ]]; then
        user_message+="LAST 10 COMMANDS:\n$last_n_cmds\n\n"
    fi

    if [[ -n "$recent_output" ]]; then
        user_message+="RECENT TERMINAL OUTPUT:\n$recent_output\n\n"
    fi

    user_message+="FAILED COMMAND: $failed_command (exit code: $exit_code)\n\n"

    # Escape for JSON
    local escaped_system_prompt
    local escaped_user_message
    escaped_system_prompt=$(jq -Rn --arg str "$(_get_llm_system_prompt)" '$str')
    escaped_user_message=$(jq -Rn --arg str "$user_message" '$str')

    # Build request body
    local request_body
    request_body=$(jq -n \
        --arg model "$OPENAI_MODEL" \
        --argjson system_prompt "$escaped_system_prompt" \
        --argjson user_message "$escaped_user_message" \
        '{
            model: $model,
            stream: true,
            options: {
                temperature: 0.1
            },
            messages: [
                {
                    role: "system",
                    content: $system_prompt
                },
                {
                    role: "user", 
                    content: $user_message
                }
            ]
        }')
    log_debug "[fix] $request_body"

    printf "\n"
    tui_status "info" "Analyzing..." 

    # Stream response and parse in real-time
    local accumulated_text=""
    local fixed_command=""

    curl -s -X POST "${OPENAI_BASE_URL}/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${OPENAI_API_KEY}" \
        -d "$request_body" | while IFS= read -r line; do

        [[ -z "$line" ]] && continue

        json_data="${line#data: }"
        [[ "$json_data" == "[DONE]" ]] && break
        
        chunk_content=$(jq -r '.choices[0].delta.content // empty' 2>/dev/null <<< "$json_data")
        accumulated_text+="$chunk_content"

        if [[ -z "$accumulated_text" ]]; then
            tui_status "info" "" false
        fi

        if [[ "$accumulated_text" == *"==="* ]]; then
            :
        else
            tui_print "dim" "$chunk_content"
        fi
    done
    printf "\n"

    if [[ "$accumulated_text" != *$'==='* ]]; then
        return $exit_code
    fi

    # Extract and clean the fixed command
    local fixed_command="${accumulated_text##*$'==='}"
    fixed_command="${fixed_command#"${fixed_command%%[![:space:]]*}"}" 
    fixed_command="${fixed_command%"${fixed_command##*[![:space:]]}"}" 

    tui_status "none" ""
    tui_status "success" "$fixed_command"
    printf "\n"
    tui_actions "Yes [y]" "No"
    read choice

    if [[ "$choice" == "y" || "$choice" == "" ]]; then       
        if [[ -n "$fixed_command" ]]; then
            if [[ -n "$ZSH_VERSION" ]]; then
                print -s "$fixed_command"
            elif [[ -n "$BASH_VERSION" ]]; then
                history -s "$fixed_command"
            fi
        fi
        eval "$fixed_command"
        eval_exit_code=$?
        echo >&2
        return $eval_exit_code
    else
        tui_status "info" "okay"
        return $exit_code
    fi
}
# =============================================================================
# From: src/tmux.sh
# =============================================================================


# ===
# in this approach, we uses tmux for logging the terminal and PROMPT_COMMAND to run the callbacks
# ===

_shai_is_on=0
_shai_session_log="/tmp/shai_session_$$.log"
_last_command=""

_get_recent_output() {
    if [[ -f "$_shai_session_log" ]]; then
        sed -n '/=== SHAI SESSION START/,$p' "$_shai_session_log" | \
        tail -n 50 | \
        grep -v "\[SHAI_" | \
        grep -v "^[[:space:]]*$" | \
        grep -v "^%[[:space:]]*$" | \
        sed 's/\x1b\[[0-9;]*m//g' | \
        tail -n 10                   
    fi
}

_trim_log() {
    if [[ -f "$_shai_session_log" ]]; then
        local line_count=$(wc -l < "$_shai_session_log")
        if [[ $line_count -gt 200 ]]; then
            tail -n 200 "$_shai_session_log" > "${_shai_session_log}.tmp"
            mv "${_shai_session_log}.tmp" "$_shai_session_log"
        fi
    fi
}

_shai_post_command() {
    local exit_code=$?
    log_debug "[_shai_post_command] exit_code=$exit_code"

    # let's trim it for good measure
    _trim_log
    
    # do not trigger if shai is not on
    if [[ $_shai_is_on -eq 0 ]]; then
        return $exit_code
    fi

    # do not trigger if command returned succesfully
    if [[ $exit_code -eq 0 ]]; then
        return $exit_code
    fi

    # do not trigger if user press ctrl^C or process was sigint / sigterm
    if [[ $exit_code -ge 128 ]] && [[ $exit_code -le 165 ]]; then
        return $exit_code
    fi
    
    local last_cmd
    if [[ -n "$ZSH_VERSION" ]]; then
        last_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')
    else
        last_cmd=$(history 1 2>/dev/null | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
    fi
    log_debug "[_shai_post_command] last_cmd=$last_cmd"
    
    # do not trigger if shai or empty command
    [[ "$last_cmd" == shai* ]] && return $exit_code
    [[ -z "$last_cmd" ]] && return $exit_code
    
    _last_command="$last_cmd"
    
    # summon the genie
    local recent_output=$(_get_recent_output)
    fix "$last_cmd" "$exit_code" "$recent_output"
    return $?
}

_check_tmux() {
    if ! command -v tmux >/dev/null 2>&1; then
        echo >&2 "Error: tmux is not installed."
        echo >&2 "Install it with:"
        echo >&2 "  macOS: brew install tmux"
        echo >&2 "  Ubuntu/Debian: sudo apt install tmux"
        echo >&2 "  CentOS/RHEL: sudo yum install tmux"
        return 1
    fi
    return 0
}

_start_tmux_session() {
    local session_name="shai_$$ "
    
    tmux kill-session -t "$session_name" 2>/dev/null

    tmux new-session -d -s "$session_name" \; \
        send-keys "source '$SHAI_MAIN_PATH' && shai on" Enter \; \
        attach-session -t "$session_name"
}

_shai_enable_in_tmux() {
    if [[ -z "$TMUX" ]]; then
        echo >&2 "Error: This function should only be called inside tmux"
        return 1
    fi
    
    echo "=== SHAI SESSION START $(date) ===" > "$_shai_session_log"
    tmux pipe-pane "cat >> '$_shai_session_log'"
    
    if [[ -n "$BASH_VERSION" ]]; then
        PROMPT_COMMAND="_shai_post_command${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
    elif [[ -n "$ZSH_VERSION" ]]; then
        autoload -Uz add-zsh-hook
        add-zsh-hook precmd _shai_post_command
    fi
    
    echo >&2 "${LOG_GRAY}shai enabled with tmux logging!${LOG_NC}"
}

_shai_disable_in_tmux() {
    if [[ -n "$TMUX" ]]; then
        tmux pipe-pane
    fi
    
    if [[ -n "$BASH_VERSION" ]]; then
        PROMPT_COMMAND="${PROMPT_COMMAND//_shai_post_command; /}"
        PROMPT_COMMAND="${PROMPT_COMMAND//_shai_post_command/}"
    elif [[ -n "$ZSH_VERSION" ]]; then
        autoload -Uz add-zsh-hook
        add-zsh-hook -d precmd _shai_post_command
    fi
}

shai() {
    case "$1" in
        on)
            if [[ $_shai_is_on -eq 1 ]]; then
                echo >&2 "${LOG_GRAY}shai already enabled.${LOG_NC}"
                return
            fi
            
            if ! _check_tmux; then
                return 1
            fi
            
            if [[ -n "$TMUX" ]]; then
                _shai_is_on=1
                _shai_enable_in_tmux
            else
                _start_tmux_session
            fi
            ;;
        off)
            if [[ $_shai_is_on -eq 0 ]]; then
                echo >&2 "${LOG_GRAY}shai is not enabled.${LOG_NC}"
                return
            fi
            
            _shai_is_on=0
            _shai_disable_in_tmux
            
            echo >&2 "${LOG_GRAY}shai disabled!${LOG_NC}"
            if [[ -n "$TMUX" ]]; then
                echo >&2 "${LOG_GRAY}You can exit tmux with: exit${LOG_NC}"
            fi
            ;;
        status)
            if [[ $_shai_is_on -eq 1 ]]; then
                echo >&2 "${LOG_GRAY}shai is ${LOG_GREEN}enabled${LOC_NC}"
                if [[ -n "$TMUX" ]]; then
                    echo >&2 "${LOG_GRAY}  - Running in tmux session: $(tmux display-message -p '#S')${LOC_NC}"
                    echo >&2 "${LOG_GRAY}  - Log file: $_shai_debug_log${LOC_NC}"
                    echo >&2 "${LOG_GRAY}  - Session file: $_shai_session_log${LOC_NC}"
                    if [[ -f "$_shai_session_log" ]]; then
                        local line_count=$(wc -l < "$_shai_session_log")
                        echo >&2 "${LOG_GRAY}  - Captured lines: $line_count${LOC_NC}"
                    fi
                fi
            else
                echo >&2 "${LOG_GRAY}shai is ${LOG_RED}disabled${LOC_NC}"
            fi
            ;;
        *)
            echo >&2 "${LOG_GRAY}Usage: shai {on|off|status}${LOC_NC}"
            ;;
    esac
}

# Cleanup on shell exit
trap 'rm -f "$_shai_session_log"' EXIT
