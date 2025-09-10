#!/bin/bash
# Fedora setup: multimedia codecs + GPU drivers (Intel / AMD / NVIDIA)

set -e

# --- Detect script directory ---
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
echo "Script directory detected as: $SCRIPT_DIR"

echo ">>> Updating system..."
sudo dnf -y upgrade --refresh

echo ">>> Enabling RPM Fusion (Free + Non-Free)..."
sudo dnf -y install \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

echo "Adding Flathub repository..."
sudo dnf -y install flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo ">>> Installing core multimedia codecs..."
sudo dnf -y install libavcodec-freeworld --allowerasing

echo ">>> Detecting GPU..."
GPU_INFO=$(lspci | grep -i "vga\|3d\|2d")

if echo "$GPU_INFO" | grep -qi nvidia; then
    echo ">>> NVIDIA GPU detected. Installing drivers..."
    sudo dnf -y install akmod-nvidia xorg-x11-drv-nvidia-cuda
    echo ">>> NVIDIA driver installation complete."

elif echo "$GPU_INFO" | grep -qi intel; then
    echo ">>> Intel GPU detected. Installing intel-media-driver..."
    sudo dnf -y install intel-media-driver --allowerasing
    echo ">>> Intel driver installation complete."

elif echo "$GPU_INFO" | grep -qi amd; then
    echo ">>> AMD GPU detected. Installing mesa-va-drivers-freeworld..."
    sudo dnf -y install mesa-va-drivers-freeworld --allowerasing
    echo ">>> AMD driver installation complete."

else
    echo ">>> No supported GPU detected. Skipping GPU driver install."
fi

echo "Installing essential packages..."
sudo dnf install -y git wget curl stow
sudo dnf install -y nvim tmux
sudo dnf install -y kvantum kf5-plasma
sudo dnf install -y fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-mozc

echo "Installing Plasma applets..."
PLASMOID_DIR="$SCRIPT_DIR/plasmoids"
if [ -d "$PLASMOID_DIR" ]; then
    for file in "$PLASMOID_DIR"/*.plasmoid; do
        echo "Installing $file..."
        plasmapkg2 --install "$file" || echo "Failed to install $file"
    done
fi

echo "Setting wallpaper..."
WALLPAPER="$HOME/.config/wallpapers/DaydreamSkytrain.png"
qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript "
var desktops = desktops();
for (i=0; i<desktops.length; i++) {
  var d = desktops[i];
  d.wallpaperPlugin = 'org.kde.image';
  d.currentConfigGroup = ['Wallpaper','org.kde.image','General'];
  d.writeConfig('Image', 'file://$WALLPAPER');
}"

echo ">>> Setup complete!"
echo ">>> Recommended: Reboot your system."
