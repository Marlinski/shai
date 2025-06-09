#!/bin/bash

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