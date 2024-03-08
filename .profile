# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
# Ubuntu make installation of Ubuntu Make binary symlink
PATH=/home/rontero/.local/share/umake/bin:$PATH

# Wine

export WINEPREFIX=~/.wine64/ WINEARCH=win64 wine64 # 64 instead of 32

# GoLang

export PATH=$PATH:/usr/local/go/bin:/home/rontero/Documents/Program-Files/go/bin
export GOPATH=$HOME/Documents/Program-Files/go

# Flutter

export PATH=$PATH:/home/rontero/Documents/Program-Files/flutter/bin
export CMAKE_MAKE_PROGRAM=/usr/bin/ninja # Compile fix
export CMAKE_CXX_COMPILER=/usr/bin/g++ # Compile fix
export CMAKE_C_COMPILER=/usr/bin/gcc # Compile fix

# Java

export PATH=$PATH:/opt/gradle/gradle-8.4/bin

# Tmux

# ~/.tmux/plugins
export PATH=$HOME/.tmux/plugins/t-smart-tmux-session-manager/bin:$PATH
# ~/.config/tmux/plugins
export PATH=$HOME/.config/tmux/plugins/t-smart-tmux-session-manager/bin:$PATH

# Neovim

export EDITOR='nvim'
export PATH=$PATH:$HOME/.local/share/nvim/mason/bin

# My Enviroment

. "$HOME/.dotfiles/.env"

# Rust

. "$HOME/.cargo/env"

