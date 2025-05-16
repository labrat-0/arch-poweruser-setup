#!/bin/bash
# Arch Linux Power User Setup Script - Tokyo Night Edition
# Author: Mick Donahue (contact@ratbyte.dev)

set -e

USERNAME="$USER"
HOME_DIR="/home/$USERNAME"

### --- Update & Install Base Packages --- ###
echo "[+] Updating and installing base packages..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm git curl zsh neovim kitty waybar wofi rofi tmux fish starship unzip fzf ripgrep lazygit base-devel unzip hyprland grim slurp swaylock ffmpegthumbnailer thunar file-roller pipewire pipewire-pulse wireplumber bluez bluez-utils sddm qt5-wayland qt6-wayland zsh-autosuggestions zsh-syntax-highlighting wl-clipboard fd

### --- Enable Services --- ###
echo "[+] Enabling required services..."
sudo systemctl enable bluetooth
sudo systemctl enable sddm

### --- Install AUR Helper (yay) --- ###
echo "[+] Installing yay (AUR helper)..."
git clone https://aur.archlinux.org/yay.git $HOME_DIR/yay
cd $HOME_DIR/yay
makepkg -si --noconfirm
cd .. && rm -rf yay

### --- Install AUR Packages --- ###
yay -S --noconfirm ttf-jetbrains-mono-nerd noto-fonts-emoji btop

### --- Setup Zsh --- ###
echo "[+] Setting up Zsh with Oh My Zsh..."
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
cat > $HOME_DIR/.zshrc <<EOF
export ZSH=\"$HOME_DIR/.oh-my-zsh\"
ZSH_THEME=\"agnoster\"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source \$ZSH/oh-my-zsh.sh
EOF

### --- Create Config Directories --- ###
echo "[+] Creating configuration directories..."
mkdir -p $HOME_DIR/.config/{hypr,waybar,kitty,wofi,nvim,swww}
mkdir -p $HOME_DIR/Pictures

### --- Download and Apply Wallpaper --- ###
echo "[+] Downloading Tokyo Night wallpaper..."
curl -Lo $HOME_DIR/Pictures/wall.jpg https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/wallpaper/tokyonight-moon.png

### --- Configure Hyprland --- ###
cat > $HOME_DIR/.config/hypr/hyprland.conf <<EOF
exec-once = swww init & swww img $HOME_DIR/Pictures/wall.jpg & waybar & kitty
monitor=,preferred,auto,1
input {
  kb_layout=us
}
general {
  gaps_in=5
  gaps_out=10
  border_size=3
  col.active_border=0xff7aa2f7
  col.inactive_border=0xff3b4261
}
decoration {
  rounding=10
  blur=true
  blur_size=5
  blur_passes=2
  drop_shadow=true
  shadow_range=20
  shadow_render_power=3
  col.shadow=0x88000000
}
EOF

### --- Configure Waybar --- ###
cat > $HOME_DIR/.config/waybar/config.json <<EOF
{
  "layer": "top",
  "position": "top",
  "modules-left": ["clock"],
  "modules-center": ["window"],
  "modules-right": ["pulseaudio", "battery", "network"]
}
EOF

cat > $HOME_DIR/.config/waybar/style.css <<EOF
* {
  font-family: JetBrainsMono Nerd Font, monospace;
  font-size: 13px;
}
window {
  background-color: rgba(26,27,38,0.95);
  border-bottom: 2px solid #7aa2f7;
}
#clock, #battery, #network, #pulseaudio {
  padding: 0 10px;
  color: #c0caf5;
}
EOF

### --- Configure Kitty --- ###
cat > $HOME_DIR/.config/kitty/kitty.conf <<EOF
font_family JetBrainsMono Nerd Font
font_size 13
background #1a1b26
foreground #c0caf5
cursor #7aa2f7
selection_background #33467c
color0  #15161e
color1  #f7768e
color2  #9ece6a
color3  #e0af68
color4  #7aa2f7
color5  #bb9af7
color6  #7dcfff
color7  #a9b1d6
EOF

### --- Setup Neovim (ThePrime-style) --- ###
echo "[+] Setting up Neovim configuration..."
git clone https://github.com/ThePrimeagen/init.lua.git $HOME_DIR/.config/nvim
cd $HOME_DIR/.config/nvim
./install.sh
cd $HOME_DIR

### --- Ensure Required Neovim Plugins --- ###
echo "[+] Installing Neovim plugins (Telescope, Harpoon, etc)..."
# Will be handled via init.lua's first launch or kickstart
nvim --headless \
  "+Lazy! sync" \
  "+qa"

### --- Set Permissions --- ###
echo "[+] Fixing permissions..."
sudo chown -R $USERNAME:$USERNAME $HOME_DIR

### --- Done --- ###
echo "[✓] Setup complete! Reboot your system and select Hyprland at login."
