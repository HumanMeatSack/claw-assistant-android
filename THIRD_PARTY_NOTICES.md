# Third-party notices

The repository contains source and preparation instructions. Model weights, reference recordings, native runtime binaries, APKs, and signing material are not committed. Running the preparation script obtains the selected assets from their upstream publishers and verifies their SHA-256 hashes. The app source license does not replace the separate terms for those assets.

## OpenClaw and Android dependencies

- The Android patch is based on OpenClaw `fc23bc864e4553c2d215e479eeec47b67a0bf943`. The preparation script preserves its MIT license and third-party notices. [Pinned OpenClaw source](https://github.com/openclaw/openclaw/tree/fc23bc864e4553c2d215e479eeec47b67a0bf943)
- Sherpa-ONNX 2.0.1 supplies the speech runtime under Apache-2.0. The script repackages only its named ARM64 Android libraries and Java classes, without modifying their bytes. ONNX Runtime carries MIT and third-party notices. [Sherpa-ONNX license](https://github.com/k2-fsa/sherpa-onnx/blob/v2.0.1/LICENSE) · [ONNX Runtime license](https://github.com/microsoft/onnxruntime/blob/main/LICENSE)
- The optional phone-local model runtime uses LiteRT-LM Android 0.18.1 and Gson, both under Apache-2.0. Their notices are retained in the prepared Android checkout. [LiteRT-LM source](https://github.com/google-ai-edge/LiteRT-LM) · [Gson source](https://github.com/google/gson)
- Android's installed offline system voice is the default assistant-panel speech output. The repository does not redistribute a system TTS voice.

## Default speech-recognition and wake assets

`./android/prepare.sh NEW_OPENCLAW_CHECKOUT` installs these assets for the developer preview:

| Asset | Upstream source and terms | Complete input SHA-256 |
| --- | --- | --- |
| Sherpa-ONNX 2.0.1 Android AAR | [Release asset](https://github.com/k2-fsa/sherpa-onnx/releases/download/v2.0.1/sherpa-onnx-2.0.1.aar), Apache-2.0 runtime with ONNX Runtime notices | `a8d09d1d32f3eb8520482c6d3d43fae674681c5b050385967c70a3c2c9bf0ee7` |
| GigaSpeech Zipformer 3.3M keyword model, 2024-01-01 | [Archive](https://github.com/k2-fsa/sherpa-onnx/releases/download/kws-models/sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01.tar.bz2), archive model card identifies Apache-2.0 | `f170013b4716e41b62b9bfd809687c207cef798ef9bc6534d524e17af9b6561a` |
| NVIDIA Parakeet TDT 0.6B v2, Sherpa int8 ONNX conversion | [Archive](https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemo-parakeet-tdt-0.6b-v2-int8.tar.bz2), [original NVIDIA model](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2), CC BY 4.0 | `6fc4426b54aa549a0019b8a75b8dea59164e71790a37ac56a045ad57f915f714` |
| Silero VAD ONNX model | [Sherpa-hosted model](https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx), [Silero source and MIT license](https://github.com/snakers4/silero-vad) | `9e2449e1087496d8d4caba907f23e0bd3f78d91fa552479bb9c23ac09cbb1fd6` |

NVIDIA trained the Parakeet weights. The Sherpa-ONNX project exported and quantized them; the prepared preview uses that existing conversion without changing the model bytes. Attribution and license text are retained in the Android Licenses screen. Neither NVIDIA nor the other upstream projects endorses this preview.

The preparation script also checks each selected archive member against a pinned SHA-256. It extracts only the named regular model files; it does not unpack sample audio, arbitrary paths, or archive links. To reuse local downloads, set `AIDEN_ANDROID_ASSET_CACHE` to a directory containing the exact upstream filenames used in `android/prepare.sh`. Cached bytes receive the same verification as downloaded bytes. A missing cache entry is downloaded from its listed HTTPS source.

## Optional Alba voice

`./android/prepare.sh --with-alba NEW_OPENCLAW_CHECKOUT` adds the following assets. This option is separate from the default system-voice build because the pinned conversion package contains conflicting licensing statements:

- The January 26, 2026 Sherpa Pocket TTS int8 archive's original `README.md` says it is for noncommercial use and links to the converter's license.
- The `LICENSE` shipped in that same archive contains CC BY 4.0 text. The [linked converter license](https://huggingface.co/KevinAHM/pocket-tts-onnx/blob/main/onnx/LICENSE) also currently contains CC BY 4.0 text.
- This project does not resolve that discrepancy or grant commercial rights to the conversion. Treat this optional recipe as a noncommercial experiment until the model distributor clarifies its terms. The script preserves the archive's original `UPSTREAM_README.md` and `LICENSE` beside the installed model files.
- Kyutai's original [Pocket TTS code](https://github.com/kyutai-labs/pocket-tts) has its own MIT license; that code license does not override the separately packaged conversion notices.

| Optional asset | Pinned source | Complete input SHA-256 |
| --- | --- | --- |
| Pocket TTS int8 ONNX conversion, 2026-01-26 | [Sherpa release archive](https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/sherpa-onnx-pocket-tts-int8-2026-01-26.tar.bz2) | `2f3b88823cbbb9bf0b2477ec8ae7b3fec417b3a87b6bb5f256dba66f2ad967cb` |
| Alba MacKenna, “Casual,” published by Kyutai | [Recording at revision `88a3419b6b950493d4eb4aaf8791ff24b6ccb1e9`](https://huggingface.co/kyutai/tts-voices/blob/88a3419b6b950493d4eb4aaf8791ff24b6ccb1e9/alba-mackenna/casual.wav), [voice card identifying CC BY 4.0](https://huggingface.co/kyutai/tts-voices#alba-mackenna) | `46264e83cb99115c3d210260e029117566d9c64f20266d10daa78107759ede3e` |

The reference recording bytes are unchanged. The app uses it to synthesize original replies; it does not imply endorsement by Alba MacKenna or Kyutai. Retain its creator, source, CC BY 4.0 attribution, and any applicable modification notices when distributing the voice assets or a build containing them. No personal greeting recording is included in this source export.

## Optional phone-local Qwen model

The preparation script does not download or bundle a chat model. The phone imports a separately obtained file through Android's document picker and verifies its complete size and SHA-256 before publishing the app-private copy.

The current runtime targets the earlier LiteRT-LM conversion of Qwen3-4B:

- Repository: [`litert-community/Qwen3-4B`](https://huggingface.co/litert-community/Qwen3-4B), Apache-2.0 model card.
- Revision: `a45912eb8a7b33d6cb92aac6a08524b9463faec0`.
- Upstream file: [`qwen3_4b_mixed_int4.litertlm`](https://huggingface.co/litert-community/Qwen3-4B/blob/a45912eb8a7b33d6cb92aac6a08524b9463faec0/qwen3_4b_mixed_int4.litertlm).
- Complete size: `2659053760` bytes.
- SHA-256: `569fe029f51e55b6377f98ebd7f6d26431bc73e1d632034f5389f2fd720da701`.

Use this exact revision. The upstream filename on `main` was replaced by a different export whose GPU requirements differ. The imported app copy is named `qwen3-4b-a45912eb.litertlm`; the download's filename need not be renamed before using the document picker. See [upstream conversion notes](https://huggingface.co/litert-community/Qwen3-4B#conversion-notes) and the [Android build guide](android/README.md).
