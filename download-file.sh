#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")" && pwd)"
artifact_path="$1"
expected_size="$2"
expected_hash="$3"
revision="3b7b650c74a5546e7fd431876c1ffa24012b746b"
snapshot="$task_root/cache/hub/models--jianchen0311--Qwen3.8-27B-Uncensored-Splash/snapshots/$revision"
case "$artifact_path" in /*|*..*) exit 64;; esac
destination="$snapshot/$artifact_path"
if test -f "$destination" && test "$(stat -f %z "$destination")" = "$expected_size" &&
  test "$(shasum -a 256 "$destination" | awk '{print $1}')" = "$expected_hash"; then
  printf 'VERIFIED cached %s %s bytes\n' "$artifact_path" "$expected_size"
  exit 0
fi
mkdir -p "$task_root/logs/download"
log_name="${artifact_path//\//_}"
origin="${DIRECT_DL_ORIGIN:-https://hf-mirror.com}"
case "$origin" in https://hf-mirror.com|https://huggingface.co) ;; *) exit 64;; esac
download() {
downloader="${DIRECT_DL_SCRIPT:-${HOME}/.agents/skills/direct-resumable-download/scripts/direct_resumable_download.sh}"
test -x "$downloader" || { printf 'Install direct-resumable-download skill or set DIRECT_DL_SCRIPT.\n' >&2; return 1; }
DIRECT_DL_SPLIT="$split" DIRECT_DL_SHA256="$expected_hash" "$downloader" \
  "$1" \
  "$(dirname "$destination")" "$(basename "$destination")" \
  > "$task_root/logs/download/$log_name.log" 2>&1
}
split=8
if test "$expected_size" -lt 32000000; then split=1; fi
if ! download "$origin/jianchen0311/Qwen3.8-27B-Uncensored-Splash/resolve/$revision/$artifact_path"; then
  # The bundled skill cannot join a relative Location header. Reinvoke the
  # same downloader with that observed URL, on the same trusted origin.
  relative="$(sed -n 's|^ERROR: cannot parse host from URL: \(/api/resolve-cache/.*\)$|\1|p' "$task_root/logs/download/$log_name.log")"
  test -n "$relative" || { tail -n 4 "$task_root/logs/download/$log_name.log"; exit 1; }
  download "$origin$relative"
fi
test "$(stat -f %z "$destination")" = "$expected_size"
actual_hash="$(shasum -a 256 "$destination" | awk '{print $1}')"
test "$actual_hash" = "$expected_hash"
printf 'VERIFIED %s %s bytes\n' "$artifact_path" "$expected_size"
