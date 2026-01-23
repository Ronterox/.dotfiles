# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Ubuntu make installation of Ubuntu Make binary symlink
PATH=$HOME/.local/share/umake/bin:$PATH

# Custom

export DOINGO_PATH="$HOME/Documents/Projects/MarkdownProjects/ANX/doing"

# Wine

export WINEPREFIX=~/.wine64/ WINEARCH=win64 wine64 # 64 instead of 32

# ASDF

export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# GoLang

# export PATH=$PATH:/usr/local/go/bin:$HOME/Documents/Program-Files/go/bin
export GOPATH=$HOME/Documents/Program-Files/go

# Flutter

# export PATH=$PATH:$HOME/Documents/Program-Files/flutter/bin
export CMAKE_MAKE_PROGRAM=/usr/bin/ninja # Compile fix
export CMAKE_CXX_COMPILER=/usr/bin/g++ # Compile fix
export CMAKE_C_COMPILER=/usr/bin/gcc # Compile fix

# Tmux

# ~/.tmux/plugins
export PATH=$HOME/.tmux/plugins/t-smart-tmux-session-manager/bin:$PATH
# ~/.config/tmux/plugins
export PATH=$HOME/.config/tmux/plugins/t-smart-tmux-session-manager/bin:$PATH

# Neovim

export EDITOR='nvim'
export MANPAGER='nvim +Man!'
export PATH=$PATH:$HOME/.local/share/nvim/mason/bin

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

export VCPKG_ROOT=$HOME/Documents/Program-Files/vcpkg
export PATH=$VCPKG_ROOT:$PATH

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Android

export ANDROID_HOME=$HOME/Documents/Program-Files/Android
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$PATH:/opt/android-studio/bin/

# Perl

export PERL5LIB=$HOME/Documents/Program-Files/perl/lib/perl5:$PERL5LIB
export PATH=$HOME/Documents/Program-Files/perl/bin:$PATH

PROGRAM_FILES="$HOME/Documents/Program-Files"
PATH="$PROGRAM_FILES/perl/${PATH:+:${PATH}}"; export PATH;
PERL5LIB="$PROGRAM_FILES/perl/lib/perl5/${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="$PROGRAM_FILES/perl/${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"$PROGRAM_FILES/perl/\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=$PROGRAM_FILES/perl5"; export PERL_MM_OPT;

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

