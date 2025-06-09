#!/bin/bash


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