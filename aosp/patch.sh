#!/usr/bin/env bash

set -e

ROOT_DIR="$(pwd)"

apply_aperture() {
    echo ">>> Applying patches: packages/apps/Aperture"
    cd "$ROOT_DIR/packages/apps/Aperture"
    git fetch https://github.com/Nothing-2A/android_packages_apps_Aperture
    git cherry-pick 9509277efc852ad8bdcce204e0d9cfe104b6d190
}

apply_wpa() {
    echo ">>> Applying patches: external/wpa_supplicant_8"
    cd "$ROOT_DIR/external/wpa_supplicant_8"
    git fetch https://github.com/Nothing-2A/android_external_wpa_supplicant_8
    git cherry-pick c4868f12d7d3e017dd131081bffb85fea85656b6
    git cherry-pick 39200b6c7b1f9ff1c1c6a6a5e4cd08c6f526d048
    git cherry-pick 37a6e255d9d68fb483d12db550028749b280509b
}

apply_frameworks_native() {
    echo ">>> Applying patches: frameworks/native"
    cd "$ROOT_DIR/frameworks/native"
    git fetch https://github.com/Nothing-2A/android_frameworks_native
    git cherry-pick 7b7807349f7b66c61444e32e4a26b025932117d8
}

apply_frameworks_base() {
    echo ">>> Applying patches: frameworks/base"
    cd "$ROOT_DIR/frameworks/base"
    git fetch https://github.com/Nothing-2A/android_frameworks_base
    git cherry-pick 77ad23a18ae3bad622a92411206f0201efc0bebe
}

show_menu() {
    echo
    echo "==== Patch Selection Menu ===="
    echo "1) packages/apps/Aperture"
    echo "2) external/wpa_supplicant_8"
    echo "3) frameworks/native"
    echo "4) frameworks/base"
    echo "5) Apply ALL"
    echo "0) Exit"
    echo "=============================="
}

while true; do
    show_menu
    read -rp "Select option(s) (e.g. 1 3 4): " choices

    for choice in $choices; do
        case "$choice" in
            1) apply_aperture ;;
            2) apply_wpa ;;
            3) apply_frameworks_native ;;
            4) apply_frameworks_base ;;
            5)
                apply_aperture
                apply_wpa
                apply_frameworks_native
                apply_frameworks_base
                ;;
            0) echo "Exiting."; exit 0 ;;
            *) echo "Invalid option: $choice" ;;
        esac
    done

    echo
    echo "✔ Selected patches applied successfully."
done
