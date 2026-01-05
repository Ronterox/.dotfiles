#!/usr/bin/env bash

# TODO: Setup the disks

# TODO: Setup i3wm

set -e

pacman -Syu --noconfirm neovim sudo nix git base-devel

nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
nix-channel --update

# Create a new file that enables the wheel group
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

useradd -m -G wheel rontero
passwd rontero

# - tells to login
su - rontero -c <<EOF
	git clone -b linux https://github.com/Ronterox/.dotfiles.git
	cd .dotfiles
	nix-env -i stow
	stow .
EOF

su - rontero
