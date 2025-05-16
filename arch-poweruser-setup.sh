#!/bin/bash
# Arch Linux Full Rice & Setup Script (Hyprland + WiFi + Desktop + Tokyo Night Theme)
# Author: Mick Donahue (ratbyte.dev)

set -euo pipefail

USERNAME="${SUDO_USER:-$USER}"
HOME_DIR="/home/$USERNAME"

echo "🛠️ Starting full Arch Linux Hyprland rice & setup for user: $USERNAME"

# --- Update system & install base packages ---
echo "🔄 Updating system & installing essential packages..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm --needed \
  base-devel git curl zsh neovim kitty waybar wofi rofi tmux fish starship unzip fzf ripgrep lazygit \
  btop pipewire pipewire-pulse wireplumber bluez bluez-utils sddm qt5-wayland qt6-wayland \
  networkmanager network-manager-applet wireless_tools wpa_supplicant linux-firmware linux-headers \
  xdg-desktop-portal xdg-desktop-portal-wlr swaylock grim slurp ffmpegthumbnailer thunar file-roller \
  wl-clipboard fd

# --- Enable NetworkManager, Bluetooth, and SDDM services ---
echo "🟢 Enabling services: NetworkManager, Bluetooth, and SDDM..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
sudo systemctl enable sddm

# --- Install yay (AUR helper) ---
echo "📦 Installing yay (AUR helper)..."
if ! command -v yay &>/dev/null; then
  git clone https://aur.archlinux.org/yay.git $HOME_DIR/yay
  cd $HOME_DIR/yay
  makepkg -si --noconfirm
  cd -
  rm -rf $HOME_DIR/yay
else
  echo "yay is already installed."
fi

# --- Install AUR packages ---
echo "📥 Installing AUR packages..."
yay -S --noconfirm ttf-jetbrains-mono-nerd noto-fonts-emoji firefox-bin hyprland-git swww-git waybar-hyprland-git

# --- Add user to wheel group for sudo access ---
echo "👤 Adding $USERNAME to wheel group..."
if ! groups $USERNAME | grep -q wheel; then
  sudo usermod -aG wheel $USERNAME
fi
sudo sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# --- Setup Zsh with Oh My Zsh and starship prompt ---
echo "🐚 Setting up Zsh, Oh My Zsh, and Starship prompt..."
chsh -s "$(command -v zsh)" $USERNAME

if [ ! -d "$HOME_DIR/.oh-my-zsh" ]; then
  sudo -u $USERNAME sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

sudo -u $USERNAME mkdir -p $HOME_DIR/.config

cat > $HOME_DIR/.zshrc <<EOF
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source \$ZSH/oh-my-zsh.sh
eval "\$(starship init zsh)"
EOF

# Install starship prompt for user
if ! command -v starship &>/dev/null; then
  curl -fsSL https://starship.rs/install.sh | sudo -u $USERNAME sh -s -- -y
fi

sudo chown $USERNAME:$USERNAME $HOME_DIR/.zshrc

# --- Setup Hyprland config ---
echo "🎨 Configuring Hyprland..."
mkdir -p $HOME_DIR/.config/hypr
mkdir -p $HOME_DIR/.config/waybar
mkdir -p $HOME_DIR/.config/kitty
mkdir -p $HOME_DIR/.config/wofi
mkdir -p $HOME_DIR/Pictures

# Download Tokyo Night wallpaper
curl -Lo $HOME_DIR/Pictures/wall.jpg https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/wallpaper/tokyonight-moon.png

cat > $HOME_DIR/.config/hypr/hyprland.conf <<EOF
exec-once = swww init
exec-once = swww img $HOME_DIR/Pictures/wall.jpg
exec-once = waybar
exec-once = kitty

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

# --- Waybar config ---
cat > $HOME_DIR/.config/waybar/config.json <<EOF
{
  "layer": "top",
  "position": "top",
  "modules-left": ["sway/workspaces"],
  "modules-center": ["sway/window"],
  "modules-right": ["pulseaudio", "battery", "network", "clock"]
}
EOF

cat > $HOME_DIR/.config/waybar/style.css <<EOF
* {
  font-family: "JetBrainsMono Nerd Font", monospace;
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

# --- Kitty terminal config ---
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

# --- Wofi launcher config ---
cat > $HOME_DIR/.config/wofi/config <<EOF
[settings]
style = tokyonight
show-icons = true
EOF

# --- Fix permissions ---
echo "🔧 Fixing permissions for $USERNAME..."
sudo chown -R $USERNAME:$USERNAME $HOME_DIR

# --- Final message ---
echo "✅ Setup complete! Reboot your system, login as $USERNAME, select Hyprland session in SDDM."
echo "🔥 Enjoy your riced Arch Linux desktop with Tokyo Night theme and full WiFi support!"

exit 0
