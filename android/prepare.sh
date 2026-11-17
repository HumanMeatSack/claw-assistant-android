#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  printf 'Usage: %s NEW_OPENCLAW_CHECKOUT\n' "$0" >&2
  exit 2
fi

preview_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
destination=$1
if [[ "$destination" != /* ]]; then
  destination="$PWD/$destination"
fi
if [[ -e "$destination" || -L "$destination" ]]; then
  printf 'Choose a new checkout directory. The target already exists.\n' >&2
  exit 2
fi

work_dir=$(mktemp -d)
trap 'rm -rf -- "$work_dir"' EXIT
commit=fc23bc864e4553c2d215e479eeec47b67a0bf943
model=sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01

fetch_asset() {
  local name=$1 url=$2
  if [[ -n "${AIDEN_ANDROID_ASSET_CACHE:-}" && -f "$AIDEN_ANDROID_ASSET_CACHE/$name" ]]; then
    cp -- "$AIDEN_ANDROID_ASSET_CACHE/$name" "$work_dir/$name"
  else
    curl --fail --location --silent --show-error --retry 2 --proto '=https' --proto-redir '=https' \
      "$url" --output "$work_dir/$name"
  fi
}

fetch_asset sherpa-onnx-2.0.1.aar \
  'https://github.com/k2-fsa/sherpa-onnx/releases/download/v2.0.1/sherpa-onnx-2.0.1.aar'
fetch_asset "$model.tar.bz2" \
  "https://github.com/k2-fsa/sherpa-onnx/releases/download/kws-models/$model.tar.bz2"

# Read only the known archive members. The original package hashes also cover the member names.
python3 - "$work_dir" "$model" <<'PY'
from hashlib import file_digest
from pathlib import Path
import sys
import tarfile
import zipfile

work = Path(sys.argv[1])
model = sys.argv[2]
aar = work / "sherpa-onnx-2.0.1.aar"
archive = work / (model + ".tar.bz2")
for path, expected in (
    (aar, "a8d09d1d32f3eb8520482c6d3d43fae674681c5b050385967c70a3c2c9bf0ee7"),
    (archive, "f170013b4716e41b62b9bfd809687c207cef798ef9bc6534d524e17af9b6561a"),
):
    with path.open("rb") as asset:
        if file_digest(asset, "sha256").hexdigest() != expected:
            raise SystemExit(f"Checksum mismatch for {path.name}")

aar_entries = (
    "R.txt",
    "AndroidManifest.xml",
    "classes.jar",
    "proguard.txt",
    "META-INF/com/android/build/gradle/aar-metadata.properties",
    "jni/arm64-v8a/libonnxruntime.so",
    "jni/arm64-v8a/libsherpa-onnx-jni.so",
)
with zipfile.ZipFile(aar) as upstream, zipfile.ZipFile(work / "sherpa-onnx-2.0.1-arm64.aar", "w") as app:
    for name in aar_entries:
        entry = zipfile.ZipInfo(name, date_time=(1980, 2, 1, 0, 0, 0))
        app.writestr(entry, upstream.read(name), compress_type=zipfile.ZIP_DEFLATED)

with tarfile.open(archive, "r:bz2") as upstream:
    files = {
        f"{part}-epoch-12-avg-2-chunk-16-left-64.int8.onnx": f"{part}.int8.onnx"
        for part in ("encoder", "decoder", "joiner")
    }
    files["tokens.txt"] = "tokens.txt"
    for source, target in files.items():
        member = upstream.getmember(f"{model}/{source}")
        if not member.isfile():
            raise SystemExit(f"Expected a regular model file: {source}")
        with upstream.extractfile(member) as handle:
            (work / target).write_bytes(handle.read())
PY

git init --quiet "$destination"
git -C "$destination" fetch --quiet --depth=1 https://github.com/openclaw/openclaw.git "$commit"
git -C "$destination" checkout --quiet --detach FETCH_HEAD
if [[ $(git -C "$destination" rev-parse HEAD) != "$commit" ]]; then
  printf 'The OpenClaw checkout did not match the expected commit.\n' >&2
  exit 1
fi
git -C "$destination" apply --check "$preview_dir/aiden-openclaw.patch"
git -C "$destination" apply "$preview_dir/aiden-openclaw.patch"

variant=apps/android/app/src/thirdPartyDebug
install -d "$destination/$variant/aiden-wake-libs" "$destination/$variant/assets/aiden-wake"
install -m 644 "$work_dir/sherpa-onnx-2.0.1-arm64.aar" "$destination/$variant/aiden-wake-libs/"
for file in encoder.int8.onnx decoder.int8.onnx joiner.int8.onnx tokens.txt; do
  install -m 644 "$work_dir/$file" "$destination/$variant/assets/aiden-wake/"
done

printf 'Prepared Aiden source at %s\n' "$destination"
printf 'Follow the build and pairing steps in android/README.md.\n'
