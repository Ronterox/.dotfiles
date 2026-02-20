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

if [[ -n $TMUX ]]; then
    base_path=$(tmux display-message -p "#{pane_current_path}")
    wd='~/$(tmux display-message -p "#S")${PWD#$base_path}'
else
    wd='\w'
fi

if [ "$color_prompt" = yes ]; then
    PS1="${debian_chroot:+($debian_chroot)}$CYAN[\!] $YELLOW\t $BLUE\$(parse_git_branch)($DARK_CYAN\u$BLUE)$WHITE:$BLUE$wd$WHITE\$ "
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

unset color_prompt force_color_prompt wd

# If this is an xterm set the title to user@host:dir
case "$TERM" in
    xterm*|rxvt*)
        ;;
    *)
        ;;
esac

if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# -------------------- Ricardo Settings Here ---------------------

# Lazy loading incoming...

asdf() {
	unset -f asdf
	. <(asdf completion bash)
	asdf "$@"
}

# These must exists for sure
_argc_completer() {
	unset -f _argc_completer
	. <(argc --argc-completions bash)
	_argc_completer "$@"
}

complete -F _argc_completer -o nospace -o nosort argc

start() {
	unset -f start
	. <(start-tool)
	start "$@"
}

zoxide() {
	unset -f zoxide
	. <(zoxide init bash)
	zoxide "$@"
}

# ------------------- Defaults -------------------

alias ls='eza --icons --header --git'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias tree='tre'
alias grep='rg'

alias nf='echo && fastfetch && backup --show && ls && echo'
alias cls='clear && ls'

alias stats="typefilesize && scc --cocomo-project-type 'optimal,0.4,0.85,1.2,0.35'"
alias battery='upower -i $(upower -e | grep battery) | egrep "percentage|time to empty"'
alias ny='TZ=America/New_York date'

# Zoxide
alias zz='__z -' # omg
alias z='__z' # lazy loading non override
alias z..='__z ..'

__z_cd() {
    builtin cd "$@" || return "$?"

    if [ "$_ZO_ECHO" = "1" ]; then
        echo "$PWD"
    fi
}

__z() {
    if [ "$#" -eq 0 ]; then
        __z_cd ~
    elif [ "$#" -eq 1 ] && [ "$1" = '-' ]; then
        if [ -n "$OLDPWD" ]; then
            __z_cd "$OLDPWD"
        else
            echo 'zoxide: $OLDPWD is not set'
            return 1
        fi
    else
        _zoxide_result="$(zoxide query -- "$@" 2>/dev/null)"
        if [ -z "$_zoxide_result" ]; then
            _zoxide_result=$(zoxide query --list --score | fzf --delimiter / --with-nth -1 --filter "$*" | sort -hr | head -1 | awk '{print $NF}')
        fi
        [ -n "$_zoxide_result" ] && __z_cd "$_zoxide_result"
    fi
}

lsz() {
    lscmd="${1:-ls}" && shift
    [ $# -eq 0 ] && path="." || path="$*"
    dir=$($lscmd "$path" | fzf --height=50% --preview "batcat \"$path\"/{} 2> /dev/null || tree -L 1 \"$path\"/{}")
    if [ ! "$dir" ]; then
        command cd "$path"
        return
    fi
    path="$path/$dir" && lsz "$lscmd" "$path"
}

lsa() { lsz "ls -a" "$@"; }
lc() { locate "$*" | fzf --border; }

h() {
    cmd="$(history | cut -c 8- | sort | uniq | fzf +s --tac --prompt='Run command: ')"
    [ ! "$cmd" ] && return
    echo "$cmd" | xclip -selection clipboard
    sleep 0.1 && xdotool key --delay {{1}} ctrl+shift+v
}
alias hcls='cat /dev/null > ~/.bash_history && history -c && clear && nf'
alias hlen='echo $(history | wc -l)'

alias df='duf'
alias dirsize='du -h -d 1 | sort -h' # I now use dust or ncdu, sometimes k4dirstat
alias netcheck='tmuxhs "sudo bandwhich" && gping google.com'
alias clean='tmuxhs "jdupes -r -m . && read && jdupes -r -d ." && tmuxvs "echo +7d Old && dust \$(fdfind --changed-before 7d) && read" && ncdu'

alias notrunbyshell='grep -l pam_env /etc/pam.d/*' # /etc/environment else /etc/profile
alias fontcache='sudo fc-cache -fv'
alias fixaudio='systemctl --user restart wireplumber pipewire pipewire-pulse'
alias textextract='flameshot gui --raw | tesseract stdin stdout'

hc() { h -d 1-$(calc $(hlen)-$HISTFILESIZE); } # Clear history
man() {
    lookup="${2:-$1}"
    command man $1 $2 || command $lookup --help | batcat || command $lookup -h | batcat;
}
wtf() { whatis $1 2> /dev/null; tldr $1 | batcat; }

# fd -p to match full path
# fd -e to match extension
# fd -g to match glob
# fd -t to match type
# Second parameters is folder
# -i ignorecase
# -x parallalel -X for all results
# {} path (optional else is passed as | command)
# {.} path without extension
# {/} just name
# {//} parent directory
# {/.} name without extension
alias fd='fdfind'

# ------------------- File Handling -------------------

rename-correct() {
    if [ $# -lt 1 ]; then
        echo -e "\nUsage: rename-correct [files path]\n"
        return
    fi
    rename 's/ /_/g; s/([A-Z])/$1/g; $_ = lc($_)' "$@"
}

# ------------------- Kitty -------------------

alias k='kitty +kitten'
# alias icat='kitty +kitten icat'
alias tconf='nvim ~/.dotfiles/.config/kitty/kitty.conf'

kitty-reload() { kill -SIGUSR1 $(pidof kitty); } # Problem: There is no kitty process, like ever

# ------------------- Apt -------------------

apti() {
    results=$(apt search "$*" | grep "$*" | awk '{print $1}')
    if [ ! "$results" ]; then
        echo "No results found!"
        return
    fi
    package=$(echo "$results" | fzf --prompt="Install: " --border --query="$*" -e)
    [ ! "$package" ] && return
    echo "Installing $package..."

    sudo apt install "$package"
}
alias aptr='apt remove'
alias aptu='apt update'
alias aptg='apt upgrade'

# ------------------- Git -------------------

# Interesting git commands

# git authors -- Who worked on what
# git effort && git whatchanged -- It shows what its been worked on
# git count -- Number of commits
# git archive-file -- Zip without .git

# git alias
# git contrib
# git bulk
# git abort
# git clear && git clear-soft
# git ignore && git ignore-io
# git fresh-branch
# git blame && git guilt
# git info && git summary
# git local-commit
# git mr && git pr # merge request and pull request
# git obliterate # remove repository file
# git rename-#tag or branch or remote
# git repl
# git show-tree
# git squash
# git undo

alias giti='git init'
alias gitu='git pull --rebase'
gitp() {
    branch=$(gitb --show-current)
    [ ! "$1" ] && remote="origin" || remote="$1"
    git push "$remote" "$branch"
}

alias gita='git add'
alias gitr='git rebase -i'
alias gitc='git commit'

alias gits='git status'
alias gitd='git diff' # remember diff-so-fancy
gitv(){ git count | grep -o '[0-9]' | paste -sd. | awk -F. '{print (NF<3?"0.":"")$0}'; }

gitac() {
    if [ $# -eq 0 ]; then
        gita -p && gitc
        return
    fi
    printf "\n" | git-magic -ap -m "$*"
}

alias gitf='git ls-files'
alias gitfe='git fetch origin --depth=10000 $(git ls-remote -h -t origin)'
alias gitrm='git rm'

alias gitb='git branch'
alias gitbc='git checkout -b'
alias gitl='git log'

alias gitw='git worktree'
alias gitwa='git worktree add'
alias gitwr='git worktree remove'
alias gitwl='git worktree list'
git-fix() {
    # If you bare clone a local repo, the following is a origin fix:
	git config --add remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
}

git-clone() {
    git clone --bare "$1" && z "$1.git" && git-fix && zz
}

git-worktree() {
    folder=$(basename "$PWD")
    current_branch=$(gitb --show-current)

    read -r -p "Are you sure you want to create a worktree of $folder? [y/n]: " confirm
    [ "$confirm" != "y" ] && return

    cd .. && git-clone "$folder"
    rip "$folder" && mv "$folder.git" "$folder"

    cd "$folder" && gitwa "$current_branch"
    echo "cd $current_branch && nvim ." > start

    cd "$current_branch" && echo "Success!"
}

# ------------------- Github -------------------

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

fileserve() {
    port=${1:-8080}
    echo "Setting up server on http://localhost:$port..."
    caddy file-server -r . -l ":$port" --browse
}

api() {
    port=${1:-2015}

    echo "Running faker on background..."
    nohup watch 'faker profile > data.json' >/dev/null 2>&1 &
    WATCH_PID=$!

    echo "Setting up api on http://localhost:$port..."
    nohup caddy file-server -r . -l ":$port" >/dev/null 2>&1 &
    CADDY_PID=$!

    read -r -p "Press any key to stop api..."
    kill $WATCH_PID $CADDY_PID 2>/dev/null || true
}

# ------------------- Viewer -------------------

[ ! -x "$(command -v batcat)" ] && alias batcat='bat'

alias cat='batcat'
alias icat='timg'
alias asciicat='img2txt'
# Markdown Command
# Mermaid Command

# ------------------- ffmpeg  -------------------

record() {
	ffmpeg -f x11grab -video_size 1920x1080 -framerate 30 -i :1 \
	-f pulse -i default \
	-c:v libx264 -preset veryfast -c:a aac output.mp4
}
alias record-low='ffmpeg -video_size 1920x1080 -framerate 30 -f x11grab -i :1 -f alsa -ac 2 -i hw:0 output.mp4'
alias record-silent='ffmpeg -f x11grab -video_size 1920x1080 -framerate 30 -i :1 output.mp4'

# ------------------- Search -------------------

alias fnew='firefox --new-window'
alias lucky='fnew https://wheelofnames.com/'
alias graph='fnew https://mermaid.js.org/'
alias draw='fnew https://excalidraw.com/'
alias imagetotext='fnew https://www.imagetotext.io/'
alias mermaidlive='fnew https://mermaid.live/'
alias wordcounter='fnew https://wordcounter.net/'
alias imagebackground='fnew https://www.cutout.pro/'

bang() {
	opts="--gb --np --unsafe"
    if [ -z "$1" ]; then
        selected="$(xh -b https://duckduckgo.com/bang.js | jq -c '.[] | {s,t}' | fzf --prompt="Bang!")"
        if [ -n "$selected" ]; then
            read -r -p "Searching $(echo "$selected" | jq -r '.s'): " search
            ddgr $opts "!$(echo "$selected" | jq -r '.t') $search"
        fi
    else
		if [ $# -gt 1 ]; then
			ddgr $opts "!ddg $*" && ddgr $opts "!$*"
		else
			ddgr $opts "!$*"
		fi
    fi
}

search() {
	if [ $# -eq 1 ]; then
		bang "$@"
		return
	fi
	bang "$@" && opencode run "$@"
}

alias ?='search'

# ------------------- Rust -------------------

export PATH="$HOME/.cargo/bin:$PATH"

cargo-clean-cache() { rip -i ~/.cargo/registry/index/* ~/.cargo/.package-cache; }

# ------------------- Java -------------------

javarun() { javac $1.java && java $1;  }

javajdk() {
    sudo update-alternatives --config java && sudo update-alternatives --config javac
    java -version && javac -version
}

alias javaclean='rip *.class'
alias javainstall='apti openjdk-*'

# ------------------- Interpreters & Editors  -------------------

docker-clean-dangling() {
    docker system prune -a
    docker volume prune -a
    docker network prune -a
    docker image prune -a
}

docker-clean() {
    # Remove all containers and volumes
    # docker rm -vf $(docker ps -aq)
    # Delete all images
    # docker rmi -f $(docker images -aq)

    docker-clean-dangling

    echo "All cleaned up!"
}

dockersize() {
    docker manifest inspect -v "$1" | jq -c 'if type == "array" then .[] else . end | select(.Descriptor.platform.architecture != "unknown")' |  jq -r '[ ( .Descriptor.platform | [ .os, .architecture, .variant, ."os.version" ] | del(..|nulls) | join("/") ), ( [ ( .OCIManifest // .SchemaV2Manifest ).layers[].size ] | add ) ] | join(" ")' | numfmt --to iec --format '%.2f' --field 2 | sort | column -t ;
}

alias py='python'
alias ipy='uvx ipython -i'

alias vi='nvim'
alias vim='nvim'

# ------------------- Tmux  -------------------

alias tmuxls='tmux ls'
alias tmuxa='tmux attach -t'
alias tmuxnew='tmux new -s'
alias tmuxvs='tmux \; split-window -v'
alias tmuxhs='tmux \; split-window -h'
alias tmuxhs='tmux \; split-window -h'
alias tmuxpopup='tmux display-popup'

tmuxkill() { tmux kill-session -t "$(tmux display-message -p '#S')"; }
alias tmuxkillall='tmux kill-server'

tmuxmail() {
    session_name=$1
    sleeptime=$2
    mailto=$3
    mailsuccess=$4
    mailerror=$5

    if [ $# -lt 5 ]; then
        echo -e "\nUsage: $0 [session_name] [sleeptime] [mailto] [mailtext]\n"
        return
    fi

    checkpane() { tmux capture-pane -pt "$session_name" -S -10; }
    pane=$(checkpane)
    while true; do
        clear
        echo "Sleeping for $sleeptime seconds, no ocurrences at $(date)..."
        sleep $sleeptime
        new_pane=$(checkpane)
        [ "$new_pane" == "$pane" ] && break
        pane=$new_pane
    done
    echo "Sending mail..."
    [ "$(echo "$pane" | grep -i -c 'error')" -eq 0 ] && mailtext="$mailsuccess" || mailtext="$mailerror"
    sendmail --target="$mailto" --text="$mailtext"
}

tmuxwatch() {
    sleeptime=$1
    mailto=$2

    if [ $# -lt 2 ]; then
        echo -e "\nUsage: tmuxwatch [sleeptime] [mailto]\n"
        return
    fi

    [ $TMUX ] && session_name=$(tmux display-message -p '#S')
    for session in $(tmux ls -F "#S"); do
        [ "$session_name" ] && [ "$session" == "$session_name" ] && continue
        tmuxmail "$session" "$sleeptime" "$mailto" "$session stopped!" "$session failed!" &
    done
}

tmuxuptime() {
    if [ -z "$1" ]; then
        session_name=$(tmux display-message -p '#S')
        if [ -z "$session_name" ]; then
            echo "No session name provided!"
            return
        fi
    else
        session_name=$1
    fi

    created=$(tmux list-sessions -F "#{session_name} #{session_created}" | grep $session_name | awk '{print $2}')
    now=$(date +%s)
    uptime=$(($now - $created))
    echo "Session uptime: $(date -d@$uptime -u +%H:%M:%S)"
}

tmux-send-cmd() {
    win_title="$1"
    cmd="$2"

    if [ -z "$win_title" ]; then
        echo "No window title provided!"
        return
    fi

    if [ -z "$cmd" ]; then
        echo "No command provided!"
        return
    fi

    tmux new-window -n "$win_title" -d && tmux send-keys -t "$win_title" "$cmd" Enter
}

send() { tmux-send-cmd "$@" "$0 $*"; }

# ------------------- Project Management -------------------

PR_DIRS=(~/Documents/Projects/ ~/.dotfiles)

cdpc() { cdp -c "start" "$@"; }

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
    session_path=$(find ${PR_DIRS[@]} -maxdepth 2 \( -name '.git' \) -prune -o -type d -ipath "*$**" | fzf --query="$*" --prompt="Project: " --border)
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
declare -A inits=(
    ["Rust"]="cargo init"
    ["Javascript"]="bun init"
    ["Java"]="gradle init"
    ["C"]="cinit"
)

devproj() {
    lang=$(find "${PR_DIRS[@]}" -maxdepth 1 -type d -ipath "*$**" -exec basename {} \; | sed s/Projects// | fzf)
    [ ! "$lang" ] && return

    echo "Language: $lang"
    read -r -p "Project Name (github works 2): " proj_name
    [ ! "$proj_name" ] && return

    cmd="${inits[$lang]}"
    read -r -p "Initialize ($cmd y/n): " start_file

    if [[ "$start_file" =~ ^[yY][eE]?[sS]?$ ]]; then
        tmpfile=$(mktemp)
        echo -e "#!/bin/bash\n\n$cmd\n\nrip start" > $tmpfile
        nvim $tmpfile && start_file=$(cat $tmpfile) || start_file=""
    fi

    command cd $(find "${PR_DIRS[@]}" -maxdepth 1 -type d -name "*$lang*" -print -quit)

    message="\n--- Don't forget to add a .gitignore file with gh-gitignore! ---\n"
    cmd="clear && giti && . start 2>/dev/null && tree -L 1 && echo -e \"\n$message\""

    if [[ "$proj_name" == *"https://github.com"* ]]; then
        proj_name="$(echo "$proj_name" | cut -d'/' -f4)/$(echo "$proj_name" | cut -d'/' -f5)"
    fi

    if [[ "$proj_name" == *"/"* ]]; then
        gh repo clone "$proj_name" -- --bare
        proj_name=$(echo "$proj_name" | cut -d'/' -f 2)

        select_branch="branch=\$(gitb -a | awk '{print \$2 ? \$2 : \$1}'| fzf)"
        echo_redirect="echo \"command cd \$branch && start || nvim .\" >> start"
        start_branch="command cd \$branch && start 2> /dev/null"

        cmd="$select_branch; gitw add \$branch && $echo_redirect && $start_branch; tree -L 1"
        mv "$proj_name.git" "$proj_name"
    fi

    mkdir -p "$proj_name" && command cd "$proj_name"; ls

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

blesh() {
	local saved_line=$READLINE_LINE
    local saved_point=$READLINE_POINT

	bind -r '"\t"'

	[ -f ~/.local/share/blesh/ble.sh ] && source ~/.local/share/blesh/ble.sh --noattach

    if [[ ${BLE_VERSION-} ]]; then
		BLE_ATTACH_OPTS="no-clear,no-check-update" ble-attach && ble-bind -f 'C-i' 'complete'

		if [[ $saved_line ]]; then
            ble/widget/insert-string "$saved_line"
            READLINE_POINT=$saved_point
        fi

        ble/widget/complete
    fi
}

if [ "$HOME" == "$PWD" ]; then
    nf
else
	echo && la && echo
	fortune ~/.local/share/fortune/quotes && echo
	bind -x '"\t": blesh'
fi

# ------------------ Forced to use this ------------------

cd() {
    echo "Use zoxide instead!"
}

# find() {
#     echo "Use fdfind instead!"
# }

rm() {
    echo "Use rip instead!"
}

# ------------------ Setting APT to be NALA ------------------

if hash nala 2> /dev/null; then
    apt() { sudo nala "$@"; }
    sudo() {
        if [ "$1" = "apt" ]; then
            shift
            command sudo nala "$@"
        else
            command sudo "$@"
        fi
    }
fi

# ------------------ Finish My Handling ------------------

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# opencode
export PATH=$HOME/.opencode/bin:$PATH

# Custom
export DOINGO_PATH="$HOME/Documents/Projects/MarkdownProjects/ANX/doing"
