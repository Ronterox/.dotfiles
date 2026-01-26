FROM archlinux:latest

# Update and install basic X11 libs
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm xorg-server xorg-apps xterm sudo

# Install your DE or WM
RUN pacman -S --noconfirm i3-wm i3status dmenu
RUN useradd -m -G wheel user

USER user
WORKDIR /home/user

CMD ["i3"]
