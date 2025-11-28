PROMPT_DIRTRIM=4

# Git Bash discovery and sourcing
GIT_EXEC_PATH="$(git --exec-path 2>/dev/null)"
COMPLETION_PATH="${GIT_EXEC_PATH%/libexec/git-core}"
COMPLETION_PATH="${COMPLETION_PATH%/lib/git-core}"
COMPLETION_PATH="$COMPLETION_PATH/share/git/completion"

[[ -f "$COMPLETION_PATH/git-completion.bash" ]] && . "$COMPLETION_PATH/git-completion.bash"
[[ -f "$COMPLETION_PATH/git-prompt.sh" ]] && . "$COMPLETION_PATH/git-prompt.sh"

# Git prompt settings
export GIT_PS1_SHOWSTASHSTATE=true
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWUPSTREAM="auto"

# Colors
mag="\[\033[30;45m\]"
grn="\[\033[30;42m\]"
ylw="\[\033[30;43m\]"
cyn="\[\033[30;46m\]"
rst="\[\033[0m\]"

# Git segment appears ONLY inside this quoted block
gitseg='`__git_ps1 " (%s) "`'

# Final PS1 (clean layout)
PS1="${mag} [\A] \
${grn} \u \
${grn}@\h \
${ylw} \w \
${cyn}${gitseg}${rst}
$ "