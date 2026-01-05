#!/usr/bin/env bash

set -e

pacman -Syu --noconfirm neovim sudo nix git base-devel

useradd -m -G wheel rontero
passwd rontero

# Create a new file that enables the wheel group
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

# - tells to login
su - rontero -c "git clone -b linux https://github.com/Ronterox/.dotfiles.git"

su - rontero
