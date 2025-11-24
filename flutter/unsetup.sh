#!/bin/bash
set -e

echo "-----------------------------------------------------"
echo "   Flutter + Android SDK + Gradle Uninstaller"
echo "-----------------------------------------------------"

BASHRC="$HOME/.bashrc"
ANDROID_HOME="$HOME/Android/Sdk"
FLUTTER_DIR="$HOME/flutter"
GRADLE_ROOT="/opt/gradle"
REMOVE_JAVA=false   # Set to true if you want to uninstall Java 17 as well

# ----------------------------------------------------------
# Helper: Remove line from ~/.bashrc if it exists
# ----------------------------------------------------------
remove_bashrc_line() {
    local line="$1"
    if grep -qF "$line" "$BASHRC"; then
        sed -i "\|$line|d" "$BASHRC"
        echo "Removed from .bashrc: $line"
    fi
}

# ----------------------------------------------------------
# 1. Remove Flutter
# ----------------------------------------------------------
echo "[1/6] Removing Flutter..."

if [ -d "$FLUTTER_DIR" ]; then
    rm -rf "$FLUTTER_DIR"
    echo "Deleted: $FLUTTER_DIR"
else
    echo "Flutter not found. Skipping."
fi

remove_bashrc_line 'export PATH="$PATH:$HOME/flutter/bin"'

# ----------------------------------------------------------
# 2. Remove Android SDK
# ----------------------------------------------------------
echo "[2/6] Removing Android SDK..."

if [ -d "$ANDROID_HOME" ]; then
    rm -rf "$ANDROID_HOME"
    echo "Deleted: $ANDROID_HOME"
else
    echo "Android SDK not found. Skipping."
fi

remove_bashrc_line "export ANDROID_HOME=$HOME/Android/Sdk"
remove_bashrc_line 'export PATH=$PATH:$ANDROID_HOME/platform-tools'
remove_bashrc_line 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin'

# ----------------------------------------------------------
# 3. Remove Gradle 8.7
# ----------------------------------------------------------
echo "[3/6] Removing Gradle..."

if [ -d "$GRADLE_ROOT" ]; then
    sudo rm -rf "$GRADLE_ROOT"
    echo "Deleted: $GRADLE_ROOT"
else
    echo "Gradle installation not found. Skipping."
fi

remove_bashrc_line "export PATH=\$PATH:/opt/gradle/gradle-8.7/bin"

# ----------------------------------------------------------
# 4. Remove Java 17 (optional)
# ----------------------------------------------------------
echo "[4/6] Java uninstall (optional)..."

if [ "$REMOVE_JAVA" = true ]; then
    echo "Uninstalling Java 17..."
    sudo pacman -Rns --noconfirm jdk17-openjdk || true
else
    echo "Skipping Java uninstall. (Set REMOVE_JAVA=true to remove it.)"
fi

# ----------------------------------------------------------
# 5. Cleanup leftover archives
# ----------------------------------------------------------
echo "[5/6] Cleaning leftover installation files..."

rm -f commandlinetools*.zip || true
rm -f gradle-*.zip || true

echo "Archives cleaned."

# ----------------------------------------------------------
# 6. Final message
# ----------------------------------------------------------
echo "-----------------------------------------------------"
echo "  UNINSTALL COMPLETE!"
echo "-----------------------------------------------------"
echo "✔ Flutter removed"
echo "✔ Android SDK removed"
echo "✔ Gradle removed"
if [ "$REMOVE_JAVA" = true ]; then
echo "✔ Java 17 removed"
else
echo "✔ Java 17 kept"
fi
echo "-----------------------------------------------------"
echo "➡️  IMPORTANT: run this in your terminal"
echo ""
echo "    source ~/.bashrc"
echo ""
echo "Your system is now clean."

