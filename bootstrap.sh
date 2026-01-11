#!/usr/bin/env bash

COWSPACE_SIZE=2G

DISK=/dev/sda
CORE_PKGS="base base-devel networkmanager linux"
HRDW_PKGS="linux-firmware intel-ucode nvidia"
BOOT_PKGS="refind efibootmgr"
BASE_PKGS="$CORE_PKGS $HRDW_PKGS $BOOT_PKGS"

HRDW_SETUP=false
SFWR_SETUP=false

cat <<EOF > ~/.vimrc
set guicursor=
set rnu
set tabstop=4
set softtabstop=4
set shiftwidth=4
set noexpandtab

set smartindent
set nowrap

set incsearch
set ignorecase
set smartcase
EOF

# Check if neovim and git are installed
if ! command -v nvim &> /dev/null || ! command -v git &> /dev/null; then
	mount -o remount,size=$COWSPACE_SIZE /run/archiso/cowspace
	pacman -Syu --noconfirm neovim git
	git clone https://github.com/NvChad/starter ~/.config/nvim
	exit 0
fi

# Hardware Setup
if [ "$HRDW_SETUP" = true ]; then
	fdisk -l && lsblk
	# n,1,default,+512M (if not exists),t,1(EFI)
	# n,2,default,default,t,23(root x86_64)
	# p (shows partitions, if not gpt do g)
	fdisk $DISK

	# if not exists
	mkfs.fat -F32 "$DISK"1
	mkfs.ext4 "$DISK"2

	mount --mkdir "$DISK"1 /mnt/boot
	mount "$DISK"2 /mnt

	# Speed for downloading packages
	reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
	pacstrap -K /mnt/ "$BASE_PKGS"

	arch-chroot /mnt/

	refind-install
fi

# Software Setup

if [ "$SFWR_SETUP" = true ]; then
	set -e

	pacman -Syu --noconfirm neovim sudo nix git

	nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
	nix-channel --update

	# Create a new file that enables the wheel group
	echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

	useradd -m -G wheel rontero
	passwd rontero

	# TODO: Setup i3wm

	# - tells to login
	su - rontero <<-EOF
		git clone -b linux https://github.com/Ronterox/.dotfiles.git
		cd .dotfiles
		nix-env -i stow
		stow .
	EOF

	su - rontero
fi
