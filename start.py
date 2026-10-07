"""Start the official binary with local config and runtime-only credentials."""
import argparse
import json
import os
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument("--context", help="Override context for staged validation")
args = parser.parse_args()
config = json.loads((ROOT / "config.json").read_text())
env = os.environ.copy()
env["HF_HUB_CACHE"] = str(ROOT / "cache" / "hub")
# Hugging Face reads refs literally; its generated refs must have no newline.
repo_cache = Path(env["HF_HUB_CACHE"]) / ("models--" + config["model"].replace("/", "--"))
(repo_cache / "refs").mkdir(parents=True, exist_ok=True)
(repo_cache / "refs/main").write_text(config["revision"])
if not env.get("SPLASH_API_KEY"):
    # Optional compatibility with an existing local oMLX deployment.
    settings_path = Path.home() / ".omlx/settings.json"
    if settings_path.is_file():
        settings = json.loads(settings_path.read_text())
        env["SPLASH_API_KEY"] = settings.get("auth", {}).get("api_key", "")
if not env.get("SPLASH_API_KEY"):
    raise SystemExit("SPLASH_API_KEY is required")
binary = shutil.which("splash") or "/opt/homebrew/bin/splash"
command = [binary, "serve", "--model", config["model"]]
for key in ("host", "port", "max_memory", "kv_format", "max_cache_disk",
            "idle_release", "default_reasoning_effort", "queue_size", "request_timeout"):
    command.extend(["--" + key.replace("_", "-"), str(config[key])])
command.extend(["--max-context", args.context or config["max_context"],
                "--persistent-cache", "--cache-dir", str(ROOT / "cache" / "prefix")])
if config["offline"]:
    command.append("--offline")
# Legacy packages do not accept --revision; the pinned HF cache ref selects it.
os.execve(command[0], command, env)
