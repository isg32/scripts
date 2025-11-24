#!/bin/bash
set -e

echo "-----------------------------------------------------"
echo "  Arch Linux — Flutter + Android SDK Full Installer"
echo "-----------------------------------------------------"

ANDROID_HOME="$HOME/Android/Sdk"
FLUTTER_DIR="$HOME/flutter"
GRADLE_VERSION=8.7
GRADLE_DIR="/opt/gradle/gradle-$GRADLE_VERSION"
CMD_TOOLS_ZIP="commandlinetools.zip"
BASHRC="$HOME/.bashrc"

# ----------------------------------------------------------
# Function to ensure a line exists in ~/.bashrc
# ----------------------------------------------------------
ensure_bashrc_line() {
    if ! grep -qxF "$1" "$BASHRC"; then
        echo "$1" >> "$BASHRC"
        echo "Added to .bashrc: $1"
    fi
}

# ----------------------------------------------------------
# 1. Install Java 17
# ----------------------------------------------------------
echo "[1/7] Installing Java 17 (LTS)..."
sudo pacman -S --noconfirm jdk17-openjdk

# ----------------------------------------------------------
# 2. Install Flutter
# ----------------------------------------------------------
echo "[2/7] Installing Flutter (stable)..."

if [ ! -d "$FLUTTER_DIR" ]; then
    git clone --depth=1 https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR"
else
    echo "Flutter directory already exists → Skipping clone."
fi

ensure_bashrc_line 'export PATH="$PATH:$HOME/flutter/bin"'

# ----------------------------------------------------------
# 3. Install Android SDK Commandline Tools
# ----------------------------------------------------------
echo "[3/7] Setting up Android SDK..."

mkdir -p "$ANDROID_HOME/cmdline-tools"

if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
    echo "Downloading Android commandline tools..."

    if [ ! -f "$CMD_TOOLS_ZIP" ]; then
        wget -O "$CMD_TOOLS_ZIP" \
        "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    fi

    echo "Unzipping Android cmdline tools..."
    unzip -o "$CMD_TOOLS_ZIP" -d "$ANDROID_HOME/cmdline-tools"
    mv -f "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
else
    echo "Android cmdline-tools already installed. Skipping."
fi

# Add PATH entries
ensure_bashrc_line "export ANDROID_HOME=$HOME/Android/Sdk"
ensure_bashrc_line 'export PATH=$PATH:$ANDROID_HOME/platform-tools'
ensure_bashrc_line 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin'

# Reload shell now so sdkmanager becomes available
echo "Reloading environment..."
source "$BASHRC"

# ----------------------------------------------------------
# 4. Install Android SDK Packages
# ----------------------------------------------------------
echo "[4/7] Installing Android SDK packages..."
source ~/.bashrc

if ! command -v sdkmanager &>/dev/null; then
    echo "❌ ERROR: sdkmanager is STILL not found."
    echo "Check: $ANDROID_HOME/cmdline-tools/latest/bin exists and contains sdkmanager"
    exit 1
fi

# Install packages ONLY if not present
install_android_pkg() {
    local package="$1"
    if sdkmanager --list | grep -q "$package"; then
        echo "$package already installed."
    else
        echo "Installing: $package"
        yes | sdkmanager "$package" --sdk_root="$ANDROID_HOME"
    fi
}

source ~/.bashrc
install_android_pkg "platform-tools"
install_android_pkg "platforms;android-35"
install_android_pkg "build-tools;35.0.0"
install_android_pkg "cmdline-tools;latest"

# ----------------------------------------------------------
# 5. Install Gradle 8.7
# ----------------------------------------------------------
echo "[5/7] Installing Gradle $GRADLE_VERSION..."

if [ ! -d "$GRADLE_DIR" ]; then
    wget "https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip"
    sudo unzip -o "gradle-$GRADLE_VERSION-bin.zip" -d /opt/gradle
else
    echo "Gradle $GRADLE_VERSION already installed → Skipping."
fi

ensure_bashrc_line "export PATH=\$PATH:/opt/gradle/gradle-$GRADLE_VERSION/bin"

# ----------------------------------------------------------
# 6. Flutter Doctor
# ----------------------------------------------------------
echo "[6/7] Running Flutter Doctor..."

# Make sure flutter is in PATH now
source "$BASHRC"

flutter doctor --android-licenses || true
flutter doctor || true

# ----------------------------------------------------------
# 7. Finished
# ----------------------------------------------------------
echo "-----------------------------------------------------"
echo "  ALL DONE! Installed:"
echo "    ✔ Java 17"
echo "    ✔ Flutter stable"
echo "    ✔ Android SDK + API 35 + build-tools 35.0.0"
echo "    ✔ Gradle $GRADLE_VERSION"
echo "-----------------------------------------------------"
echo "➡️  Run this once in your terminal:"
echo ""
echo "    source ~/.bashrc"
echo ""
echo "You are ready to build Flutter Android apps!"

