#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s [--with-alba] NEW_OPENCLAW_CHECKOUT\n' "$0"
  printf 'Default: English Parakeet ASR, Silero VAD and wake assets; Android offline system voice.\n'
  printf 'Optional --with-alba: Pocket ONNX conversion and Alba voice reference; see THIRD_PARTY_NOTICES.md.\n'
}

with_alba=false
destination=
for argument in "$@"; do
  case "$argument" in
    --with-alba) with_alba=true ;;
    --help|-h) usage; exit 0 ;;
    --*) usage >&2; exit 2 ;;
    *)
      if [[ -n "$destination" ]]; then usage >&2; exit 2; fi
      destination=$argument
      ;;
  esac
done
if [[ -z "$destination" ]]; then usage >&2; exit 2; fi

preview_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
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
asr_model=sherpa-onnx-nemo-parakeet-tdt-0.6b-v2-int8
alba_model=sherpa-onnx-pocket-tts-int8-2026-01-26

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
fetch_asset "$asr_model.tar.bz2" \
  "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/$asr_model.tar.bz2"
fetch_asset silero_vad.onnx \
  'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx'

if "$with_alba"; then
  printf '%s\n' 'Optional Alba: the pinned ONNX conversion README says non-commercial; its LICENSE says CC BY 4.0.' >&2
  printf '%s\n' 'Both original notices will be preserved. Review THIRD_PARTY_NOTICES.md before using or distributing it.' >&2
  fetch_asset "$alba_model.tar.bz2" \
    "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/$alba_model.tar.bz2"
  fetch_asset alba-casual-88a3419.wav \
    'https://huggingface.co/kyutai/tts-voices/resolve/88a3419b6b950493d4eb4aaf8791ff24b6ccb1e9/alba-mackenna/casual.wav'
fi

# Verify every complete input before unpacking, then verify only the named regular members.
python3 - "$work_dir" "$model" "$asr_model" "$alba_model" "$with_alba" <<'PY'
from hashlib import file_digest, sha256
from pathlib import Path
import sys
import tarfile
import zipfile

work = Path(sys.argv[1])
model = sys.argv[2]
asr_model = sys.argv[3]
alba_model = sys.argv[4]
with_alba = sys.argv[5] == "true"
aar = work / "sherpa-onnx-2.0.1.aar"
inputs = [
    (aar, "a8d09d1d32f3eb8520482c6d3d43fae674681c5b050385967c70a3c2c9bf0ee7"),
    (work / (model + ".tar.bz2"), "f170013b4716e41b62b9bfd809687c207cef798ef9bc6534d524e17af9b6561a"),
    (work / (asr_model + ".tar.bz2"), "6fc4426b54aa549a0019b8a75b8dea59164e71790a37ac56a045ad57f915f714"),
    (work / "silero_vad.onnx", "9e2449e1087496d8d4caba907f23e0bd3f78d91fa552479bb9c23ac09cbb1fd6"),
]
if with_alba:
    inputs += [
        (work / (alba_model + ".tar.bz2"), "2f3b88823cbbb9bf0b2477ec8ae7b3fec417b3a87b6bb5f256dba66f2ad967cb"),
        (work / "alba-casual-88a3419.wav", "46264e83cb99115c3d210260e029117566d9c64f20266d10daa78107759ede3e"),
    ]
for path, expected in inputs:
    with path.open("rb") as asset:
        if file_digest(asset, "sha256").hexdigest() != expected:
            raise SystemExit(f"Checksum mismatch for {path.name}")

aar_entries = {
    "R.txt": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "AndroidManifest.xml": "4e4afc406f4551293d45ef95eb63516774d0fa48bb0db415f6761b672ac9445a",
    "classes.jar": "0ee4991c56c19ef5a8a573b01891193d7298ffe7ebcc68f42b944361d8869d93",
    "proguard.txt": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "META-INF/com/android/build/gradle/aar-metadata.properties": "9cc8517bbdf06d879f57a2cfd6f8c6914e48800d443421cd850971945f98e7b2",
    "jni/arm64-v8a/libonnxruntime.so": "33847ad43bffe204699fd4a27f7f3603452a8cdaf2f9a44983a0bc31ffcf2da1",
    "jni/arm64-v8a/libsherpa-onnx-jni.so": "5db8f89f12b2c900a98c9e01e00c475c59db35e9437a62e36e27839ec48b5575",
}
with zipfile.ZipFile(aar) as upstream, zipfile.ZipFile(work / "sherpa-onnx-2.0.1-arm64.aar", "w") as app:
    for name, expected in aar_entries.items():
        if sum(item.filename == name for item in upstream.infolist()) != 1:
            raise SystemExit(f"Missing or duplicate AAR member: {name}")
        data = upstream.read(name)
        if sha256(data).hexdigest() != expected:
            raise SystemExit(f"Checksum mismatch for AAR member: {name}")
        entry = zipfile.ZipInfo(name, date_time=(1980, 2, 1, 0, 0, 0))
        app.writestr(entry, data, compress_type=zipfile.ZIP_DEFLATED)

def unpack_named(directory, members):
    targets = {f"{directory}/{source}": (target, expected) for source, (target, expected) in members.items()}
    seen = set()
    output = work / directory
    output.mkdir()
    # Streaming avoids rereading a large bzip2 archive for every requested member.
    # Archive names never become output paths; target names come from this fixed map.
    with tarfile.open(work / (directory + ".tar.bz2"), "r|bz2") as upstream:
        for member in upstream:
            if member.name not in targets:
                continue
            if member.name in seen or not member.isfile():
                raise SystemExit(f"Expected one regular archive member: {member.name}")
            seen.add(member.name)
            target, expected = targets[member.name]
            digest = sha256()
            with upstream.extractfile(member) as source, (output / target).open("wb") as destination:
                while chunk := source.read(1024 * 1024):
                    digest.update(chunk)
                    destination.write(chunk)
            if digest.hexdigest() != expected:
                raise SystemExit(f"Checksum mismatch for archive member: {member.name}")
    if seen != targets.keys():
        raise SystemExit(f"Missing members in {directory}: {sorted(targets.keys() - seen)}")

unpack_named(model, {
    "encoder-epoch-12-avg-2-chunk-16-left-64.int8.onnx": ("encoder.int8.onnx", "1e721676515bcd42a186979733981213c66c80db680e1cc582dfedf3be76e678"),
    "decoder-epoch-12-avg-2-chunk-16-left-64.int8.onnx": ("decoder.int8.onnx", "e40ff43297abe815e8898494c17e71bba2152d9d40fa3eb803f75d0f7533329a"),
    "joiner-epoch-12-avg-2-chunk-16-left-64.int8.onnx": ("joiner.int8.onnx", "eae9da0c7e1e6c6a3f4cc42d167899c388f6c6701b94cb96320e4f55df79624c"),
    "tokens.txt": ("tokens.txt", "fd2ded4050a55d2b1578870ba8697d02371980217806b7558bd0a5cc60f3ba53"),
})
unpack_named(asr_model, {
    "encoder.int8.onnx": ("encoder.int8.onnx", "92a10bd9c23936ea0566c29f963bc57c2a5df4261b6a8921c39abea66557ca8b"),
    "decoder.int8.onnx": ("decoder.int8.onnx", "4d097bae3bac5c96018d5293ba39f1b657296102b142affda40378f38b020f41"),
    "joiner.int8.onnx": ("joiner.int8.onnx", "77a29f3e5ac7d37074e0af465391b80f314015d5b97f0f90c6c7767f1d56f428"),
    "tokens.txt": ("tokens.txt", "ec182b70dd42113aff6c5372c75cac58c952443eb22322f57bbd7f53977d497d"),
})
if with_alba:
    unpack_named(alba_model, {
        "lm_flow.int8.onnx": ("lm_flow.int8.onnx", "8d627d235c44a597da908e1085ebe241cbbe358964c502c5a5063d18851a5529"),
        "lm_main.int8.onnx": ("lm_main.int8.onnx", "bfc0c7e7e3d72864fa3bb2ee499f62f21ddc1474b885f5f3ca570f8be73e787e"),
        "encoder.onnx": ("encoder.onnx", "e8f2f6d301ffb96e398b138a7dc6d3038622d236044636b73d920bab85890260"),
        "decoder.int8.onnx": ("decoder.int8.onnx", "12b0857402d31aead94df19d6783b4350d1f740e811f3a3202c70ad89ae11eea"),
        "text_conditioner.onnx": ("text_conditioner.onnx", "0b84e837d7bfaf2c896627b03e3f080320309f37f4fc7df7698c644f7ba5e6b1"),
        "vocab.json": ("vocab.json", "6fb646346cf931016f70c4921aab0900ce7a304b893cb02135c74e294abfea01"),
        "token_scores.json": ("token_scores.json", "5be2f278caf9b9800741f0fd82bff677f4943ec764c356f907213434b622d958"),
        "README.md": ("UPSTREAM_README.md", "2d05e627fe4fa3c625e822efcd20ad2ca62eb3b4fc1d67ae2625cb106b4f689c"),
        "LICENSE": ("LICENSE", "fe7b4ce83b8381cc5b216bbb4af73c570688d1b819c73bbaed8ca401f4677cd6"),
    })
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
if [[ ! -s "$destination/$variant/assets/aiden-wake/keywords.txt" ]]; then
  printf 'The applied source patch is missing its wake definition: assets/aiden-wake/keywords.txt must be nonempty.\n' >&2
  exit 1
fi
install -d "$destination/$variant/aiden-wake-libs" "$destination/$variant/assets/aiden-wake" \
  "$destination/$variant/assets/aiden-asr/parakeet-v2"
install -m 644 "$work_dir/sherpa-onnx-2.0.1-arm64.aar" "$destination/$variant/aiden-wake-libs/"
for file in encoder.int8.onnx decoder.int8.onnx joiner.int8.onnx tokens.txt; do
  install -m 644 "$work_dir/$model/$file" "$destination/$variant/assets/aiden-wake/"
  install -m 644 "$work_dir/$asr_model/$file" "$destination/$variant/assets/aiden-asr/parakeet-v2/"
done
install -m 644 "$work_dir/silero_vad.onnx" "$destination/$variant/assets/aiden-asr/"
if "$with_alba"; then
  install -d "$destination/$variant/assets/aiden-alba"
  for file in lm_flow.int8.onnx lm_main.int8.onnx encoder.onnx decoder.int8.onnx text_conditioner.onnx vocab.json token_scores.json UPSTREAM_README.md LICENSE; do
    install -m 644 "$work_dir/$alba_model/$file" "$destination/$variant/assets/aiden-alba/"
  done
  install -m 644 "$work_dir/alba-casual-88a3419.wav" "$destination/$variant/assets/aiden-alba/alba.wav"
fi

printf 'Prepared Aiden source at %s\n' "$destination"
if "$with_alba"; then
  printf 'Optional Alba assets installed; retain their original model and voice notices.\n'
else
  printf 'Alba assets omitted; the preview uses Android offline system speech.\n'
fi
printf 'Follow the build and pairing steps in android/README.md.\n'
