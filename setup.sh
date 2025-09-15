#!/bin/bash
# Fedora setup: multimedia codecs + GPU drivers (Intel / AMD / NVIDIA)

set -e

# --- Detect script directory ---
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
echo -e "Script directory detected as: $SCRIPT_DIR\n"

echo ">>> Updating system..."
sudo dnf -y upgrade --refresh
echo -e "--------------------\n"

echo ">>> Enabling RPM Fusion (Free + Non-Free)..."
sudo dnf -y install \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
echo -e "--------------------\n"

echo "Adding Flathub repository..."
sudo dnf -y install flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
echo -e "--------------------\n"

echo ">>> Installing core multimedia codecs..."
sudo dnf -y install libavcodec-freeworld --allowerasing
echo -e "--------------------\n"

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
echo -e "--------------------\n"

echo "Installing essential packages..."
sudo dnf install -y \
    git wget curl stow \
    kvantum kf5-plasma \
    fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-mozc
echo -e "--------------------\n"

echo "Installing Plasma applets..."
PLASMOID_DIR="$SCRIPT_DIR/plasma/plasmoids"
if [ -d "$PLASMOID_DIR" ]; then
    for file in "$PLASMOID_DIR"/*.plasmoid; do
        echo "Installing $file..."
        plasmapkg2 --install "$file" || echo "Failed to install $file"
    done
fi
echo -e "--------------------\n"

echo "Installing Layan Plasma global theme from $LAYAN_DIR..."
LAYAN_LOOKFEEL_DIR="$SCRIPT_DIR/plasma/look-and-feel/com.github.vinceliuice.Layan"
LAYAN_PLASMA_DIR="$SCRIPT_DIR/plasma/desktoptheme/Layan"
LAYAN_AURORAE_DIR="$SCRIPT_DIR/aurorae/themes/Layan"
TELA_ICON_DIR="$SCRIPT_DIR/icons/Tela"
LOOKFEEL_DIR="$HOME/.local/share/plasma/look-and-feel"
PLASMA_DIR="$HOME/.local/share/plasma/desktoptheme"
AURORAE_DIR="$HOME/.local/share/aurorae/themes"
ICON_DIR="$HOME/.local/share/icons"
[[ ! -d ${PLASMA_DIR} ]] && mkdir -p ${PLASMA_DIR}
[[ ! -d ${LOOKFEEL_DIR} ]] && mkdir -p ${LOOKFEEL_DIR}
[[ ! -d ${AURORAE_DIR} ]] && mkdir -p ${AURORAE_DIR}
[[ ! -d ${ICON_DIR} ]] && mkdir -p ${ICON_DIR}
cp -rf "$LAYAN_LOOKFEEL_DIR" "$LOOKFEEL_DIR"
cp -rf "$LAYAN_PLASMA_DIR" "$PLASMA_DIR"
cp -rf "$LAYAN_AURORAE_DIR" "$AURORAE_DIR"
cp -rf "$TELA_ICON_DIR" "$ICON_DIR"
echo -e "--------------------\n"

echo "Adding wallpaper..."
WALLPAPER_DIR="$HOME/.local/share/wallpapers"
WALLPAPER="$WALLPAPER_DIR/DaydreamSkytrain.png"
mkdir -p "$WALLPAPER_DIR"
cp -f "$SCRIPT_DIR/wallpapers/DaydreamSkytrain.png" "$WALLPAPER"
echo -e "--------------------\n"

PLASMA_SCRIPT=$(sed \
        -e "s|__WALLPAPER_PATH__|$WALLPAPER|" \
    "$SCRIPT_DIR/plasma-setup.js.in")
qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript "$PLASMA_SCRIPT"
echo -e "--------------------\n"

echo "Installing dependencies for Homebrew..."
sudo dnf install -y \
    curl \
    git \
    file \
    bzip2 \
    gzip \
    xz \
    sudo \
    make \
    gcc \
    glibc-devel \
    libffi-devel \
    bison \
    zlib-devel \
    readline-devel \
    which
echo -e "--------------------\n"

if command -v brew >/dev/null 2>&1; then
    echo "Homebrew already installed. Skipping installation."
else
    echo "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Verifying brew installation..."
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew --version
echo -e "--------------------\n"

echo "Installing pipx via Homebrew..."
brew install pipx
echo -e "--------------------\n"

echo "Installing packages for neovim..."
sudo dnf install -y \
    nvim tmux \
    lua5.1 luarocks \
    python3-pip \
    nodejs npm \
    rust cargo

sudo npm install -g neovim
echo -e "--------------------\n"

echo "Installing system packages for formatters..."
sudo dnf install -y \
    python3-black \
    python3-isort \
    clang-tools-extra \
    texlive-latexindent-bin \
    rustfmt
echo -e "--------------------\n"

echo "Installing Python-based formatters..."
pipx install \
    beautysh \
    cmakelang \
    mdformat
echo -e "--------------------\n"

echo "Installing Node.js-based formatters..."
sudo npm install -g \
    prettier \
    markdown-toc
echo -e "--------------------\n"

echo "Installing Cargo-based formatter (stylua)..."
cargo install stylua || true
echo -e "--------------------\n"

echo "Installing system packages for LSPs and providers..."
sudo dnf install -y \
    rust-analyzer \
    nodejs-bash-language-server
echo -e "--------------------\n"

echo "Installing Python-based LSPs and providers..."
pipx install \
    python-lsp-server \
    pynvim \
    ruff \
    cmake-language-server
echo -e "--------------------\n"

echo "Installing Node.js-based LSPs..."
sudo npm install -g \
    vscode-langservers-extracted \
    yaml-language-server
echo -e "--------------------\n"

echo "Installing Cargo-based LSPs..."
cargo install stylua || true
echo -e "--------------------\n"

echo "Installing LSPs via Homebrew..."
brew install ltex-ls
brew install lua-language-server
brew install texlab
echo -e "--------------------\n"

echo ">>> Setup complete!"
echo ">>> Recommended: Reboot your system."
