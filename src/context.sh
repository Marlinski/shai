#!/bin/bash

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