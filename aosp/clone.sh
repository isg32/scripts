#!/usr/bin/env bash
# clone_and_patch_nothing.sh
# Clone all repos from docs into their respective directories and cherry-pick required commits.
# Usage: ./clone_and_patch_nothing.sh
set -o pipefail

# ---------------------------
# Config: repo list
# Fields: url | dest_path | commit_sha (empty if none) | optional (yes/no)
# ---------------------------
repos=$(cat <<'REPOS'
https://github.com/Nothing-2A/android_device_nothing_Aerodactyl|device/nothing/Aerodactyl||no
https://github.com/Nothing-2A/android_device_nothing_Aerodactyl-kernel|device/nothing/Aerodactyl-kernel||no
https://gitlab.com/nothing-2a/proprietary_vendor_nothing_Aerodactyl|vendor/nothing/Aerodactyl||no
https://gitlab.com/nothing-2a/proprietary_vendor_nothing_Pacman|vendor/nothing/Pacman||no
https://gitlab.com/nothing-2a/proprietary_vendor_nothing_PacmanPro|vendor/nothing/PacmanPro||no
https://github.com/Nothing-2A/android_device_mediatek_sepolicy_vndr|device/mediatek/sepolicy_vndr||no
https://github.com/Nothing-2A/android_hardware_mediatek|hardware/mediatek||no
https://github.com/Nothing-2A/android_packages_apps_ParanoidGlyph|packages/apps/ParanoidGlyph||no
https://github.com/Pong-Development/packages_apps_GlyphAdapter|packages/apps/GlyphAdapter||no
https://github.com/Nothing-2A/android_packages_apps_Aperture|packages/apps/Aperture|a4c34aa57ed56de60f29349a1e6d20cf8160ca15|no
https://github.com/Nothing-2A/android_external_wpa_supplicant_8|external/wpa_supplicant_8|39200b6c7b1f9ff1c1c6a6a5e4cd08c6f526d048|no
https://github.com/Nothing-2A/android_external_wpa_supplicant_8|external/wpa_supplicant_8|37a6e255d9d68fb483d12db550028749b280509b|no
https://github.com/Nothing-2A/android_system_core|system/core|8ff6e7a68523c3b870d8dcd5713c71ea15b43dd2|optional
https://github.com/Nothing-2A/android_system_core|system/core|0d5990a96c5e6a404887f5575c5d00bcbbaaef74|optional
https://github.com/Nothing-2A/android_kernel_nothing_mt6886|kernel/nothing/mt6886||no
https://github.com/Nothing-2A/android_kernel_modules_nothing_mt6886|kernel/nothing/modules_mt6886||no
REPOS
)

# ---------------------------
# Helpers
# ---------------------------
print() { printf '%s\n' "$*"; }
err() { printf 'ERROR: %s\n' "$*" >&2; }

ensure_parent_dir() {
  dest="$1"
  parent=$(dirname "$dest")
  if [ ! -d "$parent" ]; then
    mkdir -p "$parent"
    print "Created parent dir: $parent"
  fi
}

default_checkout_branch() {
  local repodir="$1"
  # Try to detect origin HEAD branch
  branch=$(git -C "$repodir" remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p' | tr -d '\r')
  if [ -n "$branch" ]; then
    echo "$branch"
    return
  fi
  # fallback try main/master
  if git -C "$repodir" show-ref --verify --quiet refs/heads/main; then
    echo "main" && return
  fi
  if git -C "$repodir" show-ref --verify --quiet refs/heads/master; then
    echo "master" && return
  fi
  # fallback to first local branch or detached
  local first=$(git -C "$repodir" for-each-ref --format='%(refname:short)' refs/heads | head -n1)
  if [ -n "$first" ]; then
    echo "$first" && return
  fi
  echo ""  # no branch detected
}

# Cherry-pick commit, attempt to fetch if commit not present
do_cherrypick() {
  local dest="$1"
  local sha="$2"
  local optional="$3"
  local url="$4"

  print "  -> Attempt cherry-pick $sha"

  # 1) Try normal fetch
  git -C "$dest" fetch --all --tags --prune >/dev/null 2>&1

  # 2) If commit does not exist, fetch it directly from remote repo
  if ! git -C "$dest" cat-file -e "$sha" 2>/dev/null; then
    print "    commit missing locally — fetching specifically from $url ..."
    git -C "$dest" fetch "$url" "$sha" || {
      if [ "$optional" = "optional" ]; then
        print "    OPTIONAL patch failed — skipping."
        return 0
      else
        err "    FAILED: commit $sha not found in $url"
        return 2
      fi
    }
  fi

  # 3) Now cherry-pick it
  if git -C "$dest" cherry-pick -x "$sha"; then
    print "    cherry-pick successful."
    return 0
  else
    if [ "$optional" = "optional" ]; then
      print "    OPTIONAL cherry-pick failed — skipping."
      git -C "$dest" cherry-pick --abort
      return 0
    fi

    err "    Cherry-pick conflict! Resolve manually:"
    err "    cd $dest && git status"
    err "    After fixing: git cherry-pick --continue"
    return 3
  fi
}

# ---------------------------
# Main loop
# ---------------------------
print "Starting clone & patch process..."
failed=0

while IFS='|' read -r url dest commit optional; do
  # trim whitespace
  url="${url#"${url%%[![:space:]]*}"}"
  url="${url%"${url##*[![:space:]]}"}"
  dest="${dest#"${dest%%[![:space:]]*}"}"
  dest="${dest%"${dest##*[![:space:]]}"}"
  commit="${commit#"${commit%%[![:space:]]*}"}"
  commit="${commit%"${commit##*[![:space:]]}"}"
  optional="${optional#"${optional%%[![:space:]]*}"}"
  optional="${optional%"${optional##*[![:space:]]}"}"

  print ""
  print "Processing: $url -> $dest"
  ensure_parent_dir "$dest"
  if [ -d "$dest/.git" ]; then
    print "  * Repo exists; fetching updates"
    git -C "$dest" remote set-url origin "$url" 2>/dev/null || true
    git -C "$dest" fetch --all --tags --prune || print "    (warning) fetch failed"
  else
    print "  * Cloning into $dest ..."
    if git clone "$url" "$dest"; then
      print "    clone succeeded."
    else
      err "    clone FAILED for $url -> $dest"
      failed=$((failed+1))
      # if clone fails and patch is optional, continue; if not optional, continue to next but mark fail
      continue
    fi
  fi

  # checkout a sensible branch (prefer origin HEAD -> main/master)
  branch=$(default_checkout_branch "$dest")
  if [ -n "$branch" ]; then
    print "  * Checking out branch: $branch"
    git -C "$dest" checkout "$branch" >/dev/null 2>&1 || git -C "$dest" checkout -b "$branch" || print "    (warning) couldn't checkout $branch"
  else
    print "  * No specific branch detected; staying on current branch."
  fi

  # run cherry-pick(s) if commit specified
  if [ -n "$commit" ]; then
    # If there are multiple commits separated by comma, handle them
    IFS=',' read -ra commits_arr <<< "$commit"
    for sha in "${commits_arr[@]}"; do
      sha="${sha// /}"  # remove spaces
      if [ -z "$sha" ]; then continue; fi
      do_cherrypick "$dest" "$sha" "$optional"
      rc=$?
      if [ $rc -eq 2 ]; then
        failed=$((failed+1))
        # non-optional missing commit -> continue to next repo
        break
      elif [ $rc -eq 3 ]; then
        # conflict: stop processing further repos to let user fix
        err "Stopping further operations due to conflict in $dest."
        exit 4
      fi
    done
  fi

done <<< "$repos"

print ""
if [ "$failed" -gt 0 ]; then
  err "Completed with $failed error(s). See messages above."
  exit 1
fi

print "All done."
exit 0

