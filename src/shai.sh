#!/bin/bash

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

source "${SHAI_SCRIPT_DIR}/config.sh"
source "${SHAI_SCRIPT_DIR}/tui.sh"
source "${SHAI_SCRIPT_DIR}/logging.sh"
source "${SHAI_SCRIPT_DIR}/context.sh"
source "${SHAI_SCRIPT_DIR}/llm_prompt.sh"
source "${SHAI_SCRIPT_DIR}/llm.sh"
source "${SHAI_SCRIPT_DIR}/tmux.sh"