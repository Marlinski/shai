#!/bin/bash

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