#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")" && pwd)"
manifest="$task_root/cache/hub/models--jianchen0311--Qwen3.8-27B-Uncensored-Splash/snapshots/3b7b650c74a5546e7fd431876c1ffa24012b746b/manifest.json"
# Bootstrap the pinned manifest before trusting its artifact list.
/bin/bash "$task_root/download-file.sh" manifest.json 14160 36021d0b8ccb666ab5cd7d343feb995f71bd06f04b6b2a2c259e290c60428151
# This orchestrates the skill's downloader; it does not implement transfers.
jq -r '.artifacts[] | [.path, (.size|tostring), .sha256] | @tsv' "$manifest" |
  xargs -n 3 -P 3 /bin/bash "$task_root/download-file.sh"
