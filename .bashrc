# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return ;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth:erasedups

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=5000
HISTFILESIZE=5000

export HISTIGNORE="ls:lsd:h:history:pwd:clear:cls:hc:q:exit:cd ..:cd"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes ;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

parse_git_branch() { git branch --show-current 2> /dev/null; }

CYAN="\[\033[01;36m\]"
YELLOW="\[\033[01;33m\]"
BLUE="\[\033[01;34m\]"
WHITE="\[\033[00m\]"
DARK_CYAN="\[\033[00;36m\]"

if [ "$color_prompt" = yes ]; then
    PS1="${debian_chroot:+($debian_chroot)}$CYAN[\!] $YELLOW\t $BLUE\$(parse_git_branch)($DARK_CYAN\u$BLUE)$WHITE:$BLUE\w$WHITE\$ "
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
    xterm*|rxvt*)
        # PS1="$PS1"
        ;;
    *)
        ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# -------------------- Ricardo Settings Here ---------------------

# ------------------- Defaults -------------------

alias bconf='nvim ~/.dotfiles/.bashrc'

alias q='exit'
alias nf='neofetch && ls'
alias cls='clear && ls'

ls-cd() {
    lscmd="$1" && shift
    [ $# -eq 0 ] && path="." || path="$*"
    dir=$($lscmd "$path" | fzf --height=50% --preview "batcat \"$path\"/{} 2> /dev/null || tree -L 1 \"$path\"/{}")
    if [ ! "$dir" ]; then 
       cd "$path"
       return
    fi
    path="$path/$dir" && ls-cd "$lscmd" "$path"
}

lsd() { ls-cd "ls" "$@"; }
lsa() { ls-cd "ls -a" "$@"; }
lc() { locate "$*" | fzf --border; }

h() { 
    cmd="$(history | fzf +s --tac --prompt='Run command: ' | sed 's/ *[0-9]* *//')"
    [ ! "$cmd" ] && return
    echo "$cmd" | xclip -selection clipboard
    sleep 0.1 && xdotool key --delay {{1}} ctrl+shift+v
}
alias hcls='cat /dev/null > ~/.bash_history && history -c && clear && nf'
alias hlen='echo $(history | wc -l)'

alias dirsize='du -h -d 1'
alias notrunbyshell='grep -l pam_env /etc/pam.d/*' # /etc/environment else /etc/profile
alias fontcache='sudo fc-cache -fv'
alias fixaudio='systemctl --user restart wireplumber pipewire pipewire-pulse'

hc() { h -d 1-$(calc $(hlen)-$HISTFILESIZE); } # Clear history
man() { command man $1 || command $1 --help | batcat || command $1 -h | batcat; }
wtf() { whatis $1 2> /dev/null; tldr $1 | batcat; }

lastCd=$HOME
cd() {
    lastCd=$PWD
    command cd "$@"
}

alias cdd='cd "$lastCd"'

# ------------------- File Handling -------------------

rename-file() {
    if [ $# -lt 1 ]; then
        echo -e "\nUsage: rename-file [files path]\n"
        return
    fi
    rename 's/ /_/g; s/([A-Z])/$1/g; $_ = lc($_)' "$@"

}

# ------------------- Kitty -------------------

alias k='kitty +kitten'
alias icat='kitty +kitten icat'
alias tconf='nvim ~/.dotfiles/.config/kitty/kitty.conf'

kitty-reload() { kill -SIGUSR1 $(pidof kitty); } # Problem: There is no kitty process, like ever

# ------------------- Apt -------------------

# apti() { 
#     results=$(apt search "$*")
#     if [ ! "$results" ]; then
#         echo "No results found!"
#         return
#     fi
#     package=$(echo "$results" | fzf --prompt="Install: " --border)
#     [ ! "$package" ] && return
#     echo "Installing $package..."
# }
alias apti='apt install'
alias aptr='apt remove'
alias aptup='apt update'
alias aptug='apt upgrade'

# ------------------- Git -------------------

alias giti='git init'
alias gitu='git pull'
alias gitp='git push origin'

alias gita='git add'
alias gitr='git restore'
alias gitac='gita . && git commit'
alias gitc='git commit'

alias gits='git status'
alias gitd='git diff'

alias gitf='git ls-files'
alias gitrm='git rm'

alias gitb='git branch'
alias gitbc='git checkout'
alias gitl='git log'

alias gitw='git worktree'
alias gitwa='git worktree add'
alias gitwl='git worktree list'
alias git-clone='git clone --bare'

git-worktree() {
    folder=$(basename "$PWD")
    current_branch=$(gitb --show-current)

    read -r -p "Are you sure you want to create a worktree of $folder? [y/n]: " confirm
    [ "$confirm" != "y" ] && return

    cd .. && git-clone "$folder"
    rm -rf "$folder" && mv "$folder.git" "$folder"

    cd "$folder" && gitwa "$current_branch"
    echo "cd $current_branch && nvim ." > start

    cd "$current_branch" && echo "Success!"
}

alias gh-auth='gh auth login'
gh-open(){
    repo=$(gh repo list -L 100 | fzf --prompt="Open Repo:" --border | awk '{print $1}')
    [ ! "$repo" ] && return
    gh repo view --web "$repo"
}

GH_BASE_URL="https://api.github.com"
GH_RAW_URL="https://raw.githubusercontent.com"

gh-lsf() {
    user=$1
    repo=$2
    branch=$3
    recursive=$4
    curl -s "$GH_BASE_URL/repos/$user/$repo/git/trees/$branch?recursive=${recursive:-0}" | jq -r '.tree[] | select(.type == "blob") | .path'
}

gh-get-raw() {
    user=$1
    repo=$2
    branch=$3
    file=$4
    curl -s "$GH_RAW_URL/$user/$repo/$branch/$file"
}

gh-gitignore() {
    file=$(gh-lsf github gitignore main | fzf --prompt="Select .gitignore:" --border)
    [ ! "$file" ] && return

    gh-get-raw github gitignore main "$file" >> .gitignore
}

# ------------------- Web Dev -------------------

localh() { python3 -m http.server $@; }

# ------------------- Viewer -------------------

alias cat='batcat'
# Markdown Command
# Mermaid Command

# ------------------- Search -------------------

alias lucky='firefox --new-window https://wheelofnames.com/'
alias graph='firefox --new-window https://mermaid.js.org/'
alias draw='firefox --new-window https://excalidraw.com/'
yt(){ firefox --new-window "https://www.youtube.com/search?q=$*"; }
search(){ firefox --new-window "https://www.google.com/search?q=$*"; }
psearch(){ firefox --private-window "https://www.google.com/search?q=$*"; }

alias ?='search'
alias ??='psearch'

# ------------------- Conda -------------------

alias conda='mamba'

condact() { 
    if [ $# -eq 0 ]; then
        conda activate $(condalist | awk '{print $1}' | fzf); 
        return
    fi
    conda activate $1
}
alias condeact='conda deactivate'

alias condalist='conda env list'
alias condel='command conda remove --all --name'

alias condaclean='conda clean --all'
alias condaconfig='command conda config --show'

condcreate() {
    pattern='envs_dirs:(\s*- (/.*/envs))*'
    if [[ "$(condaconfig)" =~ $pattern ]]; then
        i=0
        for match in ${BASH_REMATCH[2]}; do
            [[ $match == '-' ]] && continue
            echo "[$i] $match"
            paths["$i"]=$match
            i=$((i+1))
        done
    fi

    if [ $# -lt 2 ]; then
        echo -e "\nUsage: condacreate [env name] [env path num] [packages...]\n"
        return
    fi

    path=${paths[$2]}
    [[ ! "$path" ]] && echo "Error: Path not found!" && return

    path+=/$1
    shift 2
    cmd="mamba create -c conda-forge -p $path $*"

    echo "$cmd" && $cmd
}

# ------------------- Interpreters & Editors  -------------------

javarun() { javac $1.java && java $1;  }

alias docker='sudo docker'
alias py='python'

alias vi='nvim'
alias vim='nvim'
alias viconf='cd ~/.config/nvim && nvim .'

# ------------------- Tmux  -------------------

alias tmuxls='tmux ls'
alias tmuxa='tmux attach -t'
alias tmuxnew='tmux new -s'

tmux-send-cmd() {
    if [ -z "$1" ]; then
        echo "Usage: tmux-send-cmd <window-name> <command>"
        return
    fi
    win_name=$1
    shift 1
    tmux new-window -d -n "$win_name" && tmux send-keys -t "$win_name" "$*" Enter
}

tmux-sessions() {
    session_name=$(tmux ls | awk '{print $1}' | tr -d ':' | fzf --prompt="Session: " --border --height=50% --preview="tmux list-windows -t {}")
    [ ! "$session_name" ] && return

    if [ -z $TMUX ]; then
        tmux a -t "$session_name"
    else
        tmux switch-client -t "$session_name"
    fi
}

# ------------------- Project Management -------------------

PR_DIRS=(~/Documents/Projects/ ~/.dotfiles /media/rontero/EXTRicardo/ProjectsHeavy/)

cdpc() { cdp -c ". start || nvim ." $@; }

export -f cdpc

cdp() {
    cmd="tree -L 1"
    while getopts ":c:" opt; do
        case $opt in
            c)
                cmd=$OPTARG
                shift 2
                ;;
            *)
                echo "Invalid option: -$OPTARG" >&2
                return
        esac
    done

    # foreach ignoredir -name $ignoredir -o
    session_path=$(find ${PR_DIRS[@]} -maxdepth 2 \( -name '.git' \) -prune -o -type d -ipath "*$**" | fzf --query=$* --prompt="Project: " --border)
    [ ! "$session_path" ] && return
    session_name=$(basename "$session_path" | tr -d '.' )

    if ! tmux has-session -t "$session_name" 2> /dev/null; then
        tmux new-session -d -s "$session_name" -c "$session_path"
        tmux send-keys -t "$session_name" "$cmd" ENTER
    fi

    if [ -z $TMUX ]; then
        tmux a -t "$session_name"
    else
        tmux switch-client -t "$session_name"
    fi
}

# develop new project
devproj() {
    lang=$(find "${PR_DIRS[@]}" -maxdepth 1 -type d -ipath "*$**" -exec basename {} \; | sed s/Projects// | fzf)
    [ ! "$lang" ] && return

    echo "Language: $lang"
    read -r -p "Project Name (github works 2): " proj_name
    [ ! "$proj_name" ] && return
    read -r -p "Start File (Optional): " start_file

    cd $(find "${PR_DIRS[@]}" -maxdepth 1 -type d -name "*$lang*" -print -quit)

    message="\n--- Don't forget to add a .gitignore file with gh-gitignore! ---\n"
    cmd="giti && . start 2>/dev/null && tree -L 1 && echo -e \"\n$message\""

    if [[ "$proj_name" == *"https://github.com"* ]]; then
        proj_name="$(echo "$proj_name" | cut -d'/' -f4)/$(echo "$proj_name" | cut -d'/' -f5)"
    fi

    if [[ "$proj_name" == *"/"* ]]; then
        gh repo clone "$proj_name" -- --bare 
        proj_name=$(echo "$proj_name" | cut -d'/' -f 2)
        cmd="branch=\$(gitb -a | awk '{print \$2 ? \$2 : \$1}'| fzf); gitw add \$branch && cd \$branch && . start 2> /dev/null; tree -L 1"
        mv "$proj_name.git" "$proj_name"
    fi

    mkdir -p "$proj_name" && cd "$proj_name"; ls

    [ "$start_file" ] && echo "$start_file" > start
    cdp -c "$cmd" "$proj_name"
} 

# ------------------- Startup -------------------

bind '"\e\e[C": forward-word' # Jump words with ctrl
bind '"\e\e[D": backward-word' # Backward

bind '"\C-f":"\C-acdpc \n"'
bind '"\C-t":"\C-atmux-sessions \n"'
bind '"\C-h":"\C-acheat \n"'
bind '"\C-r":"\C-ah \n"'
bind '"\eq":"\C-aqalc \n"' # alt + q

shopt -s autocd

clear && figlet 'Hello There' && nf

# ------------------ Setting APT to be NALA ------------------

if hash nala 2> /dev/null; then
    apt() {
        sudo nala "$@"
    }
    sudo() {
        if [ "$1" = "apt" ]; then
            shift
            command sudo nala "$@"
        else
            command sudo "$@"
        fi
    }
fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/rontero/Documents/Program-Files/mambaforge/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/rontero/Documents/Program-Files/mambaforge/etc/profile.d/conda.sh" ]; then
        . "/home/rontero/Documents/Program-Files/mambaforge/etc/profile.d/conda.sh"
    else
        export PATH="/home/rontero/Documents/Program-Files/mambaforge/bin:$PATH"
    fi
fi
unset __conda_setup

if [ -f "/home/rontero/Documents/Program-Files/mambaforge/etc/profile.d/mamba.sh" ]; then
    . "/home/rontero/Documents/Program-Files/mambaforge/etc/profile.d/mamba.sh"
fi
# <<< conda initialize <<<

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Zoxide
_z_cd() {
    cd "$@" || return "$?"

    if [ "$_ZO_ECHO" = "1" ]; then
        echo "$PWD"
    fi
}

z() {
    if [ "$#" -eq 0 ]; then
        _z_cd ~
    elif [ "$#" -eq 1 ] && [ "$1" = '-' ]; then
        if [ -n "$OLDPWD" ]; then
            _z_cd "$OLDPWD"
        else
            echo 'zoxide: $OLDPWD is not set'
            return 1
        fi
    else
        _zoxide_result="$(zoxide query -- "$@")" && _z_cd "$_zoxide_result"
    fi
}

zi() {
    _zoxide_result="$(zoxide query -i -- "$@")" && _z_cd "$_zoxide_result"
}


alias za='zoxide add'

alias zq='zoxide query'
alias zqi='zoxide query -i'

alias zr='zoxide remove'
zri() {
    _zoxide_result="$(zoxide query -i -- "$@")" && zoxide remove "$_zoxide_result"
}


_zoxide_hook() {
    if [ -z "${_ZO_PWD}" ]; then
        _ZO_PWD="${PWD}"
    elif [ "${_ZO_PWD}" != "${PWD}" ]; then
        _ZO_PWD="${PWD}"
        zoxide add "$(pwd -L)"
    fi
}

case "$PROMPT_COMMAND" in
    *_zoxide_hook*) ;;
    *) PROMPT_COMMAND="_zoxide_hook${PROMPT_COMMAND:+;${PROMPT_COMMAND}}" ;;
esac

. "$HOME/.cargo/env"
