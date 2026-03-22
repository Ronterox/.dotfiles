FROM archlinux:latest

# This is to work with x11docker until I learn to share my GUI through LXC

# Update and install basic X11 libs
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm xorg-server xorg-apps xterm sudo

# Install DE/WM and ricing tools (remove i3lock first - will install i3lock-color later)
RUN pacman -S --noconfirm \
    i3-wm i3status i3blocks dmenu terminator \
    picom feh lightdm lightdm-gtk-greeter \
    ttf-font-awesome ttf-ubuntu-font-family \
    materia-gtk-theme papirus-icon-theme lxappearance \
    alsa-utils playerctl polkit-gnome \
    python-dbus python-gobject git base-devel sudo

# Create user first (needed for building AUR packages)
RUN useradd -m -G wheel user && \
    echo "user ALL=(ALL) ALL" >> /etc/sudoers

# Build i3lock-color from AUR as user, then install as root
RUN su - user -c "cd /tmp && git clone https://aur.archlinux.org/i3lock-color.git && cd i3lock-color && makepkg -s --noconfirm" && \
    pacman -U /tmp/i3lock-color/*.zst --noconfirm

# Copy i3 config files to /opt for any user to use
COPY i3_config /opt/i3_config

# Create setup script
RUN printf '#!/bin/bash\nCURRENT_USER=$(whoami)\nmkdir -p /home/$CURRENT_USER/.config/i3\nmkdir -p /home/$CURRENT_USER/.config/i3blocks\nmkdir -p /home/$CURRENT_USER/.config/scripts\ncp /opt/i3_config/config /home/$CURRENT_USER/.config/i3/config\ncp /opt/i3_config/i3blocks/i3blocks.conf /home/$CURRENT_USER/.config/i3blocks/i3blocks.conf\ncp -r /opt/i3_config/scripts/* /home/$CURRENT_USER/.config/scripts/\nchmod +x /home/$CURRENT_USER/.config/scripts/*\nexec i3\n' > /usr/local/bin/start-i3 && chmod +x /usr/local/bin/start-i3

CMD ["/usr/local/bin/start-i3"]
