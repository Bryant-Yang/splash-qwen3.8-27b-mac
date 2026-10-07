"""Verify every pinned package artifact before starting the engine."""
import hashlib
import json
import argparse
import shutil
from pathlib import Path

root = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument("--clean-parts", action="store_true")
args = parser.parse_args()
config = json.loads((root / "config.json").read_text())
snapshot = root / "cache/hub" / ("models--" + config["model"].replace("/", "--")) / "snapshots" / config["revision"]
manifest = json.loads((snapshot / "manifest.json").read_text())
failures = []
total = 0
for artifact in manifest["artifacts"]:
    path = snapshot / artifact["path"]
    if not path.is_relative_to(snapshot) or ".." in Path(artifact["path"]).parts:
        raise SystemExit("Unsafe artifact path")
    if not path.is_file() or path.stat().st_size != artifact["size"]:
        failures.append({"path": artifact["path"], "error": "missing_or_wrong_size"})
        continue
    with path.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    if digest != artifact["sha256"]:
        failures.append({"path": artifact["path"], "error": "sha256_mismatch"})
    total += path.stat().st_size
report = {"revision": config["revision"], "artifacts": len(manifest["artifacts"]),
          "verified_bytes": total, "failures": failures,
          "manifest_sha256": hashlib.sha256((snapshot / "manifest.json").read_bytes()).hexdigest()}
(root / "reports").mkdir(exist_ok=True)
(root / "reports/model-integrity.json").write_text(json.dumps(report, indent=2))
print(json.dumps(report))
if args.clean_parts and not failures:
    removed = 0
    for artifact in manifest["artifacts"]:
        parts = snapshot / (artifact["path"] + ".parts")
        if parts.is_dir() and not parts.is_symlink():
            shutil.rmtree(parts)
            removed += 1
    print(f"Removed {removed} verified-download temporary parts directories; final weights retained.")
raise SystemExit(bool(failures))
