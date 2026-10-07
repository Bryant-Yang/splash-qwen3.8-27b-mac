#!/bin/bash
# Requires Apple Silicon macOS, Homebrew and the direct-resumable-download skill.
# Usage: ./setup.sh; then export SPLASH_API_KEY and run ./start.sh.
# config.json reflects a 48 GiB Mac; lower memory/context limits on smaller Macs.
set -euo pipefail
task_root="$(cd "$(dirname "$0")" && pwd)"
brew install incoai/tap/splash jq
/bin/bash "$task_root/download-model.sh"
splash_prefix="$(brew --prefix splash)"
"$splash_prefix/libexec/python/bin/python3" "$task_root/verify-model.py"
model_parent="${HOME}/Library/Application Support/Splash/models/jianchen0311"
model_link="$model_parent/Qwen3.8-27B-Uncensored-Splash"
snapshot="$task_root/cache/hub/models--jianchen0311--Qwen3.8-27B-Uncensored-Splash/snapshots/3b7b650c74a5546e7fd431876c1ffa24012b746b"
mkdir -p "$model_parent"
if test -e "$model_link" || test -L "$model_link"; then
  test -L "$model_link" && test "$(readlink "$model_link")" = "$snapshot" || {
    printf 'Existing model location differs; retained without overwriting: %s\n' "$model_link" >&2
    exit 1
  }
else
  ln -s "$snapshot" "$model_link"
fi
printf 'Ready. Set SPLASH_API_KEY in your environment, then run ./start.sh.\n'
