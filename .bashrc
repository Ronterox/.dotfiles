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
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=1000

export HISTIGNORE="ls:h:history:pwd:clear:cls:hc:q:exit:cd ..:cd"

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

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;36m\][\!]\[\033[01;33m\][\t] \[\033[02;33m\]\d \[\033[00;36m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
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

h() { 
    cmd="$(history | fzf +s --tac --prompt='Run command: ' | sed 's/ *[0-9]* *//')"
    echo "$cmd" | xclip -selection clipboard
    sleep 0.1 && xdotool key --delay {{1}} ctrl+shift+v
}
alias hcls='cat /dev/null > ~/.bash_history && history -c && clear && nf'
alias hlen='echo $(history | wc -l)'

alias dirsize='du -h -d 1'
alias notrunbyshell='grep -l pam_env /etc/pam.d/*' # /etc/environment else /etc/profile
alias fontcache='sudo fc-cache -fv'
alias fixaudio='systemctl --user restart wireplumber pipewire pipewire-pulse'

calc() { echo $1 | bc; } # Calculate

hc() { h -d 1-$(calc $(hlen)-$HISTFILESIZE); } # Clear history
man() { command man $1 || command $1 --help | batcat || command $1 -h | batcat; }
wtf() { whatis $1 2> /dev/null; tldr $1 | batcat; }

lastCd=$HOME
cd() {
    lastCd=$PWD
    command cd "$@"
}

alias cdd='cd "$lastCd"'

# ------------------- Kitty -------------------

alias k='kitty +kitten'
alias icat='kitty +kitten icat'
alias tconf='nvim ~/.dotfiles/.config/kitty/kitty.conf'

kitty-reload() {
    kill -SIGUSR1 $(pidof kitty)
}

# ------------------- Apt -------------------

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
alias gitac='gita . && git commit -am'
alias gitc='git commit -m'

alias gits='git status'
alias gitd='git diff'

alias gitf='git ls-files'
alias gitrm='git rm'

alias gitb='git branch'
alias gitbc='git checkout'
alias gitl='git log'

# ------------------- Web Dev -------------------

localh() { python3 -m http.server $@; }

# ------------------- Viewer -------------------

alias cat='batcat'
# Markdown Command
# Mermaid Command

# ------------------- Search -------------------

duck() { lynx "https://lite.duckduckgo.com/lite?kd=-1&kp=-1&q=$*"; }
bing() { lynx "www.bing.com/search?q=$*"; }
google() { lynx "https://google.com/search?q=$*"; }

export -f duck
export -f bing
export -f google

alias ?=duck
alias ??=google
alias ???=bing

duck1() { exec bash -c "duck $*"; }
google1() { exec bash -c "google $*"; }
bing1() { exec bash -c "bing $*"; }

alias ?!=duck1
alias ??!=google1
alias ???!=bing1

alias lucky='firefox --new-window https://wheelofnames.com/'
alias graph='firefox --new-window https://mermaid.js.org/'
yt(){ firefox --new-window "https://www.youtube.com/search?q=$*"; }
search(){ firefox --new-window "https://www.google.com/search?q=$*"; }
psearch(){ firefox --private-window "https://www.google.com/search?q=$*"; }

# ------------------- Conda -------------------

alias conda='mamba'

condact() { conda activate $(condalist | awk '{print $1}' | fzf); }
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
        echo -e "\nUsage: condacreate [env name] [env path num] [packages]\n"
        return
    fi

    path=${paths[$2]}
    [[ ! "$path" ]] && echo "Error: Path not found!" && return

    path+=/$1
    shift 2
    cmd="conda create -c conda-forge -p $path $*"

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

PR_DIRS=(~/Documents/Projects/ ~/.config /media/rontero/EXTRicardo1/ProjectsHeavy/)

cdpc() { cdp -c "nvim ." $@; }

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

    session_path=$(find ${PR_DIRS[@]} -maxdepth 2 -type d -ipath "*$**" | fzf --prompt="Project: " --border)
    [ ! "$session_path" ] && return
    session_name=$(basename "$session_path")

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
    lang=$(find ${PR_DIRS[@]} -maxdepth 1 -type d -ipath "*$**" -exec basename {} \; | sed s/Projects// | fzf)
    [ ! "$lang" ] && return

    echo "Language: $lang"
    read -p "Project Name: " proj_name
    [ ! "$proj_name" ] && return
    read -p "Main File Name (optional): " main_file
    return

    mkdir -p "$proj_name" && cd "$proj_name"; ls
    [ "$main_file" ] && touch "$main_file" && nvim .
}

# ------------------- Startup -------------------

bind '"\e\e[C": forward-word' # Jump words with ctrl
bind '"\e\e[D": backward-word' # Backward

bind '"\C-f":"\C-acdpc \n"' # Binding my command cdp
bind '"\C-t":"\C-atmux-sessions \n"' # Binding my command tmux-sessions
bind '"\C-h":"\C-acheat \n"' # Binding my command cheat
bind '"\C-r":"\C-ah \n"' # Binding my command h

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
