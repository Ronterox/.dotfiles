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

alias ls='eza --icons --header --git'
alias tree='tre'
alias grep='rg'

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

alias nf='echo && neofetch && backup --show && ls && echo'
alias cls='clear && ls'

alias stats="typefilesize && scc --cocomo-project-type 'optimal,0.4,0.85,1.2,0.35'"
alias battery='upower -i $(upower -e | grep battery) | egrep "percentage|time to empty"'
alias ny='TZ=America/New_York date'

lsz() {
    lscmd="${1:-ls}" && shift
    [ $# -eq 0 ] && path="." || path="$*"
    dir=$($lscmd "$path" | fzf --height=50% --preview "batcat \"$path\"/{} 2> /dev/null || tree -L 1 \"$path\"/{}")
    if [ ! "$dir" ]; then
        cd "$path"
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

alias zz='z -' # omg
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

# export <- also omg
. <(thefuck --alias)
. <(caddy completion bash)
. <(argc --argc-completions bash)
. <(start-tool)
. <(asdf completion bash)
. <(lxc completion bash)

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
git-clone() {
    # If you bare clone a local repo, the following is a origin fix:
    # git config --add remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git clone --bare "$1" && z "$1.git" && git config --add remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*" && zz
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

serve() {
    port=${1:-2015}
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

alias cat='batcat'
alias icat='timg'
alias asciicat='img2txt'
# Markdown Command
# Mermaid Command

# ------------------- Search -------------------

alias lucky='firefox --new-window https://wheelofnames.com/'
alias graph='firefox --new-window https://mermaid.js.org/'
alias draw='firefox --new-window https://excalidraw.com/'
alias imagetotext='firefox --new-window https://www.imagetotext.io/'
alias mermaidlive='firefox --new-window https://mermaid.live/'
alias wordcounter='firefox --new-window https://wordcounter.net/'
alias imagebackground='firefox --new-window https://www.cutout.pro/'

bang() {
    if [ -z "$1" ]; then
        selected="$(xh -b https://duckduckgo.com/bang.js | jq -c '.[] | {s,t}' | fzf --prompt="Bang!")"
        if [ -n "$selected" ]; then
            read -r -p "Searching $(echo "$selected" | jq -r '.s'): " search
            ddgr --gb --np "!$(echo "$selected" | jq -r '.t') $search"
        fi
    else
        ddgr --gb --np "!$*"
    fi
}

alias ?='ddgr'
alias ??='bang'

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
    docker system prune -a --volumes
    docker volume prune -a
    docker network prune -a
    docker image prune -a
}

docker-clean() {
    # Remove all containers and volumes
    docker rm -vf $(docker ps -aq)
    # Delete all images
    docker rmi -f $(docker images -aq)

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
declare -A inits
inits=(
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
        echo_redirect="echo \"command cd \$branch && . start || nvim .\" >> start"
        start_branch="command cd \$branch && . start 2> /dev/null"

        cmd="$select_branch; gitw add \$branch && $echo_redirect && $start_branch; tree -L 1"
        mv "$proj_name.git" "$proj_name"
    fi

    mkdir -p "$proj_name" && command cd "$proj_name"; ls

    [ "$start_file" ] && echo "$start_file" > start
    cdp -c "$cmd" "$proj_name"
}

rules() {
    echo "
    - [Inspiration] then now. Do now! Right now! Don't do anything else forget it all, enjoy focus
    - [Stress] close them eyes. Don't think about it, but instead about how easy it is and relax until well found solution chillax.
    - [Relax] look at list of stuff to do, pick one. And iterate on these 3 rules
    "
}

mread() {
    echo "$1 (Ctrl+D to finish)"
    eval "$2=\$(cat)"
}

project() {
    AFFIRMATIONS=(Awesome Good Great Cool Nice Perfect Amazing "Well Done")
    read -r -p "Name of the project: " proj_name

    echo "
    Name every project, and name the scope. Make sure the name of the project represents the scope of it.
    MAKE SURE YOU KNOW THE SCOPE OF IT. Always scale down.
    "

    read -r -p "Are you satisfied with the name? [y/n]: " confirm
    if [[ "$confirm" =~ ^[nN][oO]? ]]; then
        echo "Okay, let's try again."
        project
        return
    fi

    figlet -f small "$proj_name" | lolcat -a

    echo "${AFFIRMATIONS[$RANDOM % ${#AFFIRMATIONS[@]}]}."
    read -r -p "Are you thinking of any other project right now? [y/n]: " confirm

    echo "
    Finish them off, know whether the project payed for the effort already AND if it can pay it (most important)
    else scratch, make version 2 like I did with mikop. And just save the handful of useful part, drop the rest
    "

    read -r -p "Are you sure is worth to work on this project? [y/n]: " confirm
    if [[ "$confirm" =~ ^[nN][oO]? ]]; then
        echo "Okay, let's try again."
        project
        return
    fi

    echo "${AFFIRMATIONS[$RANDOM % ${#AFFIRMATIONS[@]}]}."
    mread "Explain to me why is this worth to work on: " explanation

    echo "
    You may have the intelligence, but you don't have enough reasons to do it (Is what they say).
    But you don't need any more reasons, just one good one, make sure is one that will always occur with effort alone
    "

    read -r -p "Is this that good enough reason, that makes it worth it to work on this project? [y/n]: " confirm
    if [[ "$confirm" =~ ^[nN][oO]? ]]; then
        echo "Okay, let's try again."
        project
        return
    fi

    figlet -f small "$proj_name" | lolcat
    echo "$explanation" | lolcat -a

    echo "${AFFIRMATIONS[$RANDOM % ${#AFFIRMATIONS[@]}]}."
    mread "Describe what would the first step of the project be:" first_step

    echo "
    Never do the fun stuff first. It will suck all of it out of the project.
    Do what you must do to be more productive, and do it well. The 20% that does the 80%.
    "

    read -r -p "Knowing all of this, can you do this step today, right now? [y/n]: " confirm
    if [[ "$confirm" =~ ^[nN][oO]? ]]; then
        echo "Okay, let's try again."
        project
        return
    fi

    figlet -f small "$proj_name" | lolcat
    echo "$explanation" | lolcat
    echo "
    ======================================================
    Path to completion:
    - $first_step
    - ...
    - ...
    - ...
    - ...
    "  | lolcat -a

    echo "${AFFIRMATIONS[$RANDOM % ${#AFFIRMATIONS[@]}]}."
    mread "Describe what the complete project would be like: " complete_project

    echo "
    Always have an exit plan, every moment has to be deliverable. It will never be ready.
    Perfectionism is the killer of productivity and progress. If it works, it's done. You can always make a part 2
    "

    read -r -p "So, is this project achievable, can it be completed in a fixed date? [y/n]: " confirm
    if [[ "$complete_project" =~ ^[nN][oO]? ]]; then
        echo "Okay, let's try again."
        project
        return
    fi

    figlet -f small "$proj_name" | lolcat
    echo "$explanation" | lolcat
    echo "
    ======================================================
    Path to completion:
    - $first_step
    - ...
    - ...
    - ...
    - ...
    "  | lolcat
    echo "
    ======================================================
    What makes it finished?
    ======================================================
    $complete_project
    " | lolcat -a

    deadline=""
    taken=""
    echo "${AFFIRMATIONS[$RANDOM % ${#AFFIRMATIONS[@]}]}."
    read -r -p "Let's talk about deadlines. Will it take one day? [y/n]: " confirm
    if [[ "$confirm" =~ ^[yY][eE]? ]]; then
        deadline=$(date -d "tomorrow")
        taken="one day"
    else
        declare -A deadlines
        deadlines=(
            [two days]="2 days"
            [three days]="3 days"
            [four days]="4 days"
            [five days]="5 days"
            [one week]="next week"
            [two weeks]="2 weeks"
            [three weeks]="3 weeks"
            [one month]="next month"
            [two months]="2 months"
            [four months]="4 months"
            [six months]="6 months"
            [one year]="next year"
            [two years]="2 years"
            [five years]="5 years"
        )
        # Iterate over the associative array
        for dl in "${!deadlines[@]}"; do
            echo ""
            read -n 1 -r -p "Will it take $dl? [y/n]: " confirm
            if [[ "$confirm" =~ ^[yY][eE]? ]]; then
                taken=$dl
                deadline=$(date -d "${deadlines[$dl]}")
                break
            fi
        done
    fi

    if [[ -z "$deadline" ]]; then
        read -r -p "How long will it take then? " taken
        read -r -p "Write the dateline as a full exact date: " deadline
    fi

    figlet -f small "$proj_name" | lolcat
    echo "$explanation" | lolcat
    echo "
    ======================================================
    Path to completion:
    - $first_step
    - ...
    - ...
    - ...
    - ...
    "  | lolcat
    echo "
    ======================================================
    What makes it finished?
    ======================================================
    $complete_project
    " | lolcat
    echo "
    ======================================================
    Deadline:
    ======================================================
    Will be in finished in $taken by $deadline, else it won't be finished
    " | lolcat -a

    echo "${AFFIRMATIONS[$RANDOM % ${#AFFIRMATIONS[@]}]}."
    read -r -p "How do you feel? " feeling

    rules

    read -r -p "And what about the project? " project_feeling

    figlet -f small "$proj_name" | lolcat
    echo "$explanation" | lolcat
    echo "
    ======================================================
    Path to completion:
    - $first_step
    - ...
    - ...
    - ...
    - ...
    "  | lolcat
    echo "
    ======================================================
    What makes it finished?
    ======================================================
    $complete_project
    " | lolcat
    echo "
    ======================================================
    Deadline:
    ======================================================
    Will be in finished in $taken by $deadline, else it won't be finished
    " | lolcat
    echo "
    ======================================================
    Notes:
    ======================================================
    > $feeling
    > $project_feeling
    " | lolcat -a

    echo "${AFFIRMATIONS[$RANDOM % ${#AFFIRMATIONS[@]}]} Success! Done."
    md="README.md"

    formatted_explanation=$(echo "$explanation" | fold -s -w 80 | awk '{
        print
        if (NR % 3 == 0) print ""
    }')

	cat <<-EOF >>"$md"
	# $proj_name

	*$formatted_explanation*

	**Path to completion:**
	- $first_step
	- ...
	- ...
	- ...
	- ...

	---

	#### What makes it finished?

	$complete_project

	---

	#### Deadline:

	Will be finished in $taken by $deadline, else it won't be finished

	---

	#### Notes:

	> $feeling.
	> $project_feeling.

	EOF
    echo "$md generated"

	prompt="
	I have created a README.md with my utility to clarify the project.
	Can you help see more clarity into the project and help improve this README
	so that we can have a clear development plan of what to do?

	Please feel free to look into the project file and REAMDE.md itself.
	"

	echo "$prompt"

	read -r -p "Any notes you want to add? " notes
	if [ -n "$notes" ]; then
		prompt="$prompt\nNote: $notes"
	fi

	gemini -ip "$prompt"
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

if [ "$HOME" == "$PWD" ]; then
    nf
	anx schedule 11:00 'better python>minecraft game copy>pyrefly>containers>simulation>doing cli>godot'
else
    cows=($(ls /usr/share/cowsay/cows/))
    count=$(echo ${cows[*]} | wc -w)
    cow=$(($RANDOM % $count))

    fortune ~/.local/share/fortune/quotes | cowsay -f ${cows[$cow]} | lolcat && echo && la && echo
    rules | shuf -n 1 | lolcat && echo
    source ~/.local/share/blesh/ble.sh
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

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Zoxide
_z_cd() {
    builtin cd "$@" || return "$?"

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
        _zoxide_result="$(zoxide query -- "$@" 2>/dev/null)"
        if [ -z "$_zoxide_result" ]; then
            _zoxide_result=$(zoxide query --list --score | fzf --delimiter / --with-nth -1 --filter "$*" | sort -hr | head -1 | awk '{print $NF}')
        fi
        [ -n "$_zoxide_result" ] && _z_cd "$_zoxide_result"
    fi
}

zi() {
    _zoxide_result="$(zoxide query -i -- "$@")" && _z_cd "$_zoxide_result"
}

alias za='zoxide add'

alias zq='zoxide query'
alias zqi='zoxide query -i'

alias zr='zoxide remove'
alias z..='z ..'

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

[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env" # ghcup-env

# >>> juliaup initialize >>>

# !! Contents within this block are managed by juliaup !!

case ":$PATH:" in
    *:$HOME/.juliaup/bin:*)
        ;;

    *)
        export PATH=$HOME/.juliaup/bin${PATH:+:${PATH}}
        ;;
esac

# <<< juliaup initialize <<<

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

PROGRAM_FILES="$HOME/Documents/Program-Files"
PATH="$PROGRAM_FILES/perl/${PATH:+:${PATH}}"; export PATH;
PERL5LIB="$PROGRAM_FILES/perl/lib/perl5/${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="$PROGRAM_FILES/perl/${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"$PROGRAM_FILES/perl/\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=$PROGRAM_FILES/perl5"; export PERL_MM_OPT;

