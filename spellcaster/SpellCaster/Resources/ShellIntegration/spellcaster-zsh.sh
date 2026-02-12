#!/bin/zsh
# SpellCaster Shell Integration for Zsh

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

# Report prompt start
__spellcaster_prompt_start() {
    __spellcaster_osc "PromptStart"
}

# Report prompt end
__spellcaster_prompt_end() {
    __spellcaster_osc "PromptEnd"
}

# Report command start
__spellcaster_command_start() {
    __spellcaster_osc "CommandStart"
}

# Report command end with exit status
__spellcaster_command_end() {
    __spellcaster_osc "CommandEnd=$?"
}

# precmd runs before each prompt
precmd() {
    __spellcaster_command_end
    __spellcaster_report_cwd
    __spellcaster_prompt_start
}

# preexec runs before each command
preexec() {
    __spellcaster_prompt_end
    __spellcaster_command_start
}

# Report git branch if in a git repository
__spellcaster_git_branch() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [[ -n "$branch" ]]; then
        __spellcaster_osc "GitBranch=$branch"
    fi
}

# Add git branch reporting to precmd
precmd_functions+=(__spellcaster_git_branch)

# Initial setup
__spellcaster_osc "ShellIntegrationVersion=1"
__spellcaster_report_cwd
