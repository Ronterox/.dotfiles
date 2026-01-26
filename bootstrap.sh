#!/usr/bin/env bash

# cat <<'EOF' > ./bootstrap.sh
#!/usr/bin/env bash

COWSPACE_SIZE=2G

DISK=/dev/sda
SFWR_PKGS="sudo i3-wm base-devel git" # nix
CORE_PKGS="base networkmanager linux"
HRDW_PKGS="linux-firmware intel-ucode nvidia"
BOOT_PKGS="refind efibootmgr"
BASE_PKGS="$CORE_PKGS $HRDW_PKGS $BOOT_PKGS"

EDIT_SETUP=false
HRDW_SETUP=false
SFWR_SETUP=false

# Hardware Configuration
FDISK=false
MKFS=false
MOUNT=false

PACSTRAP=false
FSTAB=false
SWAPFILE=false
BOOT=false
NETWORK=false

# Software Configuration
PACKAGES=false
NIX=false
SUDO_USER=false
DOTFILES=false

set -e

if [ ! -f /etc/arch-release ]; then
	echo "This script must be run on Arch Linux"
	exit 1
fi

# Check if neovim and git are installed
if [ "$EDIT_SETUP" = true ]; then
	if ! command -v nvim &> /dev/null || ! command -v git &> /dev/null; then
		mount -o remount,size=$COWSPACE_SIZE /run/archiso/cowspace
		pacman -Syu --noconfirm neovim git
		git clone https://github.com/NvChad/starter ~/.config/nvim
		exit 0
	fi
fi

# Hardware Setup
if [ "$HRDW_SETUP" = true ]; then
	if [ "$FDISK" = true ]; then
		fdisk -l && lsblk
		# n,1,default,+512M (if not exists),t,1(EFI)
		# n,2,default,default,t,23(root x86_64)
		# p (shows partitions, if not gpt do g)
		# TODO: I saw tehre is a cooler way to do this, also simpler
		fdisk $DISK
	fi

	if [ "$MKFS" = true ]; then
		# if not exists
		mkfs.fat -F32 "$DISK"1
		mkfs.ext4 "$DISK"2
	fi

	if [ "$MOUNT" = true ]; then
		mount "$DISK"2 /mnt
		mount --mkdir "$DISK"1 /mnt/boot
	fi

	if [ "$PACSTRAP" = true ]; then
		# Speed for downloading packages
		reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
		pacstrap -K /mnt/ $BASE_PKGS
	fi

	if [ "$FSTAB" = true ]; then
		genfstab -U /mnt >> /mnt/etc/fstab
	fi

	if [ "$SWAPFILE" = true ]; then
		arch-chroot /mnt/ <<-'MSG'
			mkswap -U clear --size 4G --file /swapfile
			swapon /swapfile
			echo "/swapfile none swap defaults 0 0" >> /etc/fstab
		MSG
	fi

	if [ "$BOOT" = true ]; then
		arch-chroot /mnt/ <<-MSG
			refind-install
			echo "\\"Boot with standard options\\" \\"root=UUID=\$(blkid -s UUID -o value ${DISK}2) rw initrd=\intel-ucode.img initrd=\initramfs-linux.img\\"" > /boot/refind_linux.conf
		MSG
	fi

	if [ "$NETWORK" = true ]; then
		arch-chroot /mnt/ <<-MSG
			systemctl enable NetworkManager
			systemctl start NetworkManager
		MSG
	fi
fi

# Software Setup
if [ "$SFWR_SETUP" = true ]; then
	# Defaults required
	# bat
	# eza
	# fastfetch
	# fortune-mod
	# fzf
	# man-db
	# man-pages
	# ripgrep
	# tmux
	# neovim
	# stow

	if [ "$PACKAGES" = true ]; then
		pacman -Syu --noconfirm $SFWR_PKGS
		git clone https://aur.archlinux.org/yay-bin.git
		cd yay-bin && makepkg -si
		# TODO: Setup i3wm
	fi

	if [ "$SUDO_USER" = true ]; then
		# Create a new file that enables the wheel group
		echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
		useradd -m -G wheel rontero
		passwd rontero
	fi

	if [ "$NIX" = true ]; then
		# TODO: Also add user to nix-users group and create the group
		nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
		nix-channel --update
		# TODO: Do not use unstable, but the stable nix channel, and reinstall nix on the user
	fi

	if [ "$DOTFILES" = true ]; then
		# - tells to login
		# TODO: Replace with home manager
		# TODO: But first let's work with stow as we work, multiple programs on nix file
		su - rontero <<-MSG
			git clone -b linux https://github.com/Ronterox/.dotfiles.git
			cd .dotfiles
		MSG
	fi
fi

# EOF

chmod +x ./bootstrap.sh

echo "$PWD/bootstrap.sh script created."
