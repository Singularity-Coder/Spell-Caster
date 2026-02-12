#!/bin/bash
# SpellCaster Shell Integration for Bash

# Only run if SPELLCASTER_SHELL_INTEGRATION is set
[[ -z "$SPELLCASTER_SHELL_INTEGRATION" ]] && return

# OSC escape sequence helper
__spellcaster_osc() {
    printf "\033]1337;%s\007" "$1"
}

# Report current directory
__spellcaster_report_cwd() {
    __spellcaster_osc "CurrentDir=$(pwd)"
}

# Report git branch if in a git repository
__spellcaster_git_branch() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [[ -n "$branch" ]]; then
        __spellcaster_osc "GitBranch=$branch"
    fi
}

# Command tracking
__spellcaster_last_exit_status=0

# PROMPT_COMMAND runs before each prompt
__spellcaster_prompt_command() {
    __spellcaster_osc "CommandEnd=$__spellcaster_last_exit_status"
    __spellcaster_report_cwd
    __spellcaster_git_branch
    __spellcaster_osc "PromptStart"
}

# Capture exit status before PROMPT_COMMAND
__spellcaster_capture_exit() {
    __spellcaster_last_exit_status=$?
}

# Set up PROMPT_COMMAND
if [[ -z "$PROMPT_COMMAND" ]]; then
    PROMPT_COMMAND="__spellcaster_capture_exit; __spellcaster_prompt_command"
else
    PROMPT_COMMAND="__spellcaster_capture_exit; __spellcaster_prompt_command; $PROMPT_COMMAND"
fi

# DEBUG trap for command start (requires extdebug)
shopt -s extdebug
__spellcaster_debug_trap() {
    if [[ "$BASH_COMMAND" != "__spellcaster_"* ]]; then
        __spellcaster_osc "PromptEnd"
        __spellcaster_osc "CommandStart"
    fi
}
trap '__spellcaster_debug_trap' DEBUG

# Initial setup
__spellcaster_osc "ShellIntegrationVersion=1"
__spellcaster_report_cwd
