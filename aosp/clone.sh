#!/usr/bin/env bash

set -e

ROOT_DIR="$(pwd)"

# ---------- Helpers ----------

list_branches() {
    git ls-remote --heads "$1" \
        | awk -F'/' '{print $NF}'
}

get_latest_branch() {
    git for-each-ref \
        --sort=-committerdate \
        --format='%(refname:short)' \
        refs/remotes/origin 2>/dev/null | head -n 1
}

clone_repo() {
    local name="$1"
    local repo_url="$2"
    local target_dir="$3"

    if [ -d "$ROOT_DIR/$target_dir/.git" ]; then
        echo "⚠️  $name already exists, skipping"
        return
    fi

    echo
    echo ">>> Fetching branches for $name"
    mapfile -t branches < <(list_branches "$repo_url")

    if [ "${#branches[@]}" -eq 0 ]; then
        echo "❌ No branches found"
        return
    fi

    echo
    echo "Available branches:"
    select branch in "${branches[@]}" "AUTO (latest)" "Cancel"; do
        case "$branch" in
            "AUTO (latest)")
                echo ">>> Determining latest branch by commit date..."
                tmp_dir="$(mktemp -d)"
                git clone --quiet --bare "$repo_url" "$tmp_dir"
                branch="$(git --git-dir="$tmp_dir" for-each-ref \
                    --sort=-committerdate \
                    --format='%(refname:short)' refs/heads | head -n 1)"
                rm -rf "$tmp_dir"
                ;;
            "Cancel")
                return
                ;;
            "")
                echo "Invalid selection"
                continue
                ;;
        esac
        break
    done

    echo ">>> Cloning $name"
    echo "    Branch: $branch"
    git clone -b "$branch" "$repo_url" "$ROOT_DIR/$target_dir"
}

# ---------- Repo Definitions ----------

repos=(
"1|device/nothing/Aerodactyl|https://github.com/Nothing-2A/android_device_nothing_Aerodactyl"
"2|device/nothing/Aerodactyl-kernel|https://github.com/Nothing-2A/android_device_nothing_Aerodactyl-kernel"
"3|vendor/nothing/Aerodactyl|https://gitlab.com/nothing-2a/proprietary_vendor_nothing_Aerodactyl"
"4|vendor/nothing/Pacman|https://gitlab.com/nothing-2a/proprietary_vendor_nothing_Pacman"
"5|vendor/nothing/PacmanPro|https://gitlab.com/nothing-2a/proprietary_vendor_nothing_PacmanPro"
"6|device/mediatek/sepolicy_vndr|https://github.com/Nothing-2A/android_device_mediatek_sepolicy_vndr"
"7|hardware/mediatek|https://github.com/Nothing-2A/android_hardware_mediatek"
"8|packages/apps/ParanoidGlyph|https://github.com/Nothing-2A/android_packages_apps_ParanoidGlyph"
"9|packages/apps/GlyphAdapter|https://github.com/Pong-Development/packages_apps_GlyphAdapter"
)

# ---------- Menu ----------

echo
echo "==== Available Repositories ===="
for repo in "${repos[@]}"; do
    IFS="|" read -r id path url <<< "$repo"
    echo "$id) $path"
done
echo "A) Clone ALL"
echo "0) Exit"
echo "================================"
echo

read -rp "Select repo(s) (e.g. 1 3 7): " selection

[[ "$selection" == "0" ]] && exit 0
[[ "$selection" == "A" ]] && selection=$(printf "%s " {1..9})

# ---------- Execution ----------

for choice in $selection; do
    for repo in "${repos[@]}"; do
        IFS="|" read -r id path url <<< "$repo"
        [[ "$choice" != "$id" ]] && continue

        clone_repo "$path" "$url" "$path"
    done
done

echo
echo "✅ Repository cloning complete."
