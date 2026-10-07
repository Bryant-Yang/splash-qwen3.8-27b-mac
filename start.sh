#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")" && pwd)"
brew_bin="${BREW_BIN:-$(command -v brew || true)}"
brew_bin="${brew_bin:-/opt/homebrew/bin/brew}"
splash_prefix="$("$brew_bin" --prefix splash)"
exec "$splash_prefix/libexec/python/bin/python3" "$task_root/start.py" "$@"
