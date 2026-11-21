# Build Claw Assistant for Android

This developer preview installs as **Aiden** with package ID `ai.openclaw.app.aiden.preview`. The patch is based on [OpenClaw commit `fc23bc86`](https://github.com/openclaw/openclaw/commit/fc23bc864e4553c2d215e479eeec47b67a0bf943). Use a new checkout so you can build the preview alongside your regular OpenClaw install.

## Build from source

Install Git, curl, Python 3.11 or later, JDK 17, Android SDK Platform 37, and pnpm 12.5.1. Point `ANDROID_HOME` to the SDK and make `adb` available if you want to install from the command line. Use a Node.js version supported by the pinned checkout, either 24.16 or later in the 24 series, or 26.1 or later.

From the root of this project, run:

```bash
./android/prepare.sh ./openclaw-src
cd openclaw-src
pnpm --filter '@openclaw/mermaid-renderer...' install --frozen-lockfile
cd apps/android
./gradlew :app:assembleThirdPartyDebug
```

Preparation checks out the pinned commit, applies the patch, and verifies downloaded runtime/speech assets before packaging them. The default assets include Sherpa-ONNX, the wake model, Parakeet offline English recognition, and Silero VAD. Qwen weights are imported separately. The default live-panel speaking voice is Android’s installed offline TTS voice.

The build uses your local debug signing key and writes the APK under `app/build/outputs/apk/thirdParty/debug/`. Future updates need the same package and signing key to preserve app data.

### Optional Alba build

To include the optional offline Alba voice, prepare a different, new checkout:

```bash
./android/prepare.sh --with-alba ./openclaw-alba-src
```

Then follow the same dependency-install and Gradle steps inside that checkout. This option downloads additional Pocket TTS/reference-voice assets and packages their notices. Review their separate license and attribution terms in [third-party notices](../THIRD_PARTY_NOTICES.md). Alba is not included in the default build.

Full Chat → **Listen** retains a separate provider chain: optional Alba, configured Gateway synthesis, then Android system TTS. That action can use a network provider when Alba is unavailable; the offline live-panel requirement does not make every full-chat playback route offline.

## Enable phone-local conversation

1. Install on an ARM64 test phone. The local runtime currently uses the GPU backend and needs sufficient free memory. The development handset is an S24 Ultra; this is not a broad compatibility claim.
2. Download the pinned [Qwen3-4B mixed INT4 LiteRT model](https://huggingface.co/litert-community/Qwen3-4B/resolve/a45912eb8a7b33d6cb92aac6a08524b9463faec0/qwen3_4b_mixed_int4.litertlm). Keep room for both the download and the app’s private imported copy.
3. Open **Settings → Voice → Local phone agent → Import Qwen3-4B model** and choose the file in Android’s document picker. Import verifies size and SHA-256 before replacing the private model copy. An unsuccessful import preserves the previous verified file.
4. Enable **Use phone model**. The choice applies to the next voice conversation. **Warm up phone model** loads it before testing; a cold first load takes longer. Local failure does not forward ordinary chat to the Gateway.
5. Install or enable an offline English Android TTS voice for the default build. Bundled Parakeet recognition and the speaking voice are separate components.

| Import field | Pinned value |
| --- | --- |
| Download filename | `qwen3_4b_mixed_int4.litertlm` |
| Model revision | `a45912eb8a7b33d6cb92aac6a08524b9463faec0` |
| Size | `2,659,053,760` bytes |
| SHA-256 | `569fe029f51e55b6377f98ebd7f6d26431bc73e1d632034f5389f2fd720da701` |

The preview accepts this artifact, rather than arbitrary `.litertlm` files. The picker grants access to one file; import copies it privately and keeps the original. No runtime model download or storage-wide permission is used.

## Open the system assistant

1. Install the APK on a test phone or emulator. For command-line installs, use `adb install <path-to-apk>` with the intended device selected.
2. Enable phone-local mode as above. Pair a Gateway only if you also want its separate conversation route or optional integrations.
3. Select **Aiden** as the default digital assistant in Android. On a compatible Galaxy, set the Side button’s long press to open the digital assistant. Other devices may offer a gesture or a different shortcut.
4. Open the panel. It starts continuous voice entry and listens again after a reply. Tap the input field to end voice mode and type. Local typed answers appear directly in the panel. For background wake, choose **Use screen → Hey Aiden hands-free → Start listening**, grant microphone/notification permissions, and leave the app. Keep the phone unlocked. The notification has a **Stop** control.
5. End voice mode with **End conversation** or **“stop conversation.”** If initial microphone admission fails, tap the microphone to retry; do not interpret every startup failure as a network outage.

Wake pauses while the phone is locked, while the app/panel is open, or while another capture owns the microphone. It may need rearming after an update, reboot, or force stop. First entry, natural interruption, follow-up listening, and Bluetooth playback need handset testing. Screen/image and sensitive message-related requests retain review flows. App-opening can hand off from the panel; arbitrary multi-screen app automation is not implemented.

## Optional Gateway and advanced integrations

Phone-local conversation does not require a paired Gateway. To use the separate Gateway conversation route, pair with your private authenticated Gateway and configure `aiden-fast` using the [Gateway guide](../gateway/README.md). The optional plugin adds host checks and explicit model/Codex requests.

Explicit **“Ask Codex”** needs the configured Gateway/Codex path and a network connection. Voice delegation carries bounded visible context from the current call; typed delegation is staged for review. This is not a downloadable Codex model on the phone.

Android local-agent tools have integration points for `aiden.phone.lookup` and `aiden.phone.control`. **Their Home Assistant/web backend is not included.** The sample Gateway plugin does not implement these methods. Treat those capabilities as custom integration work; importing Qwen alone does not enable live home control or verified search.

## Targeted tests

From `openclaw-src/apps/android`, run:

```bash
./gradlew :app:testThirdPartyDebugUnitTest \
  --tests '*AidenAssistantPanelTest' \
  --tests '*AidenAssistantPanelRenderTest' \
  --tests '*AidenAssistantSessionTest' \
  --tests '*PhoneCommandTest' \
  --tests '*PhoneQuickActionTest' \
  --tests '*PhoneUtilityActionTest' \
  --tests '*PhoneGoogleActionTest' \
  --tests '*PhoneAgentTool*Test' \
  --tests '*PhoneLocalAgent*Test' \
  --tests '*PinnedPhoneModelTest' \
  --tests '*AssistantCodexContextTest' \
  --tests '*AssistantGatewayLeaseTest' \
  --tests '*AssistantMicrophoneAdmissionTest' \
  --tests '*AlbaPlaybackDiagnosticsTest' \
  --tests '*OfflineSpeech*Test' \
  --tests '*VoiceWakeManagerTest' \
  --tests '*Parakeet*Test' \
  --tests '*AlbaPcmTest' \
  --tests '*AndroidLicenseNoticesTest'
```

Unit tests do not establish audible quality, real-time interruption behavior, or end-to-end latency. Use the [handset checklist](../docs/demo.md), recording cold and warm runs separately.

The patch retains OpenClaw’s MIT notices. Runtime, ASR, wake, VAD, imported Qwen, and optional voice assets each retain their own licenses. Review [third-party notices](../THIRD_PARTY_NOTICES.md), the preparation script’s pinned checksums, and asset README files in the prepared checkout. The project’s MIT license is not a blanket license for downloaded weights or reference audio.
