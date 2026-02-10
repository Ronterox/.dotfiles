FROM archlinux:latest

# This is to work with x11docker until I learn to share my GUI through LXC

# Update and install basic X11 libs
RUN pacman -Syu --noconfirm && \
	pacman -S --noconfirm xorg-server xorg-apps xterm sudo

# Install your DE or WM
RUN pacman -S --noconfirm i3-wm i3status i3lock i3blocks dmenu terminator
RUN useradd -m -G wheel user

USER user
WORKDIR /home/user

CMD ["i3"]
