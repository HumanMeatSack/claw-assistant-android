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

The preparation script checks out the pinned OpenClaw commit, applies the patch, and verifies the SHA-256 hashes of the Sherpa-ONNX runtime and wake model before unpacking the files the app uses. The build uses your local Android debug signing key and writes the APK under `app/build/outputs/apk/thirdParty/debug/`.

## Pair and start talking

1. Install the APK on a test phone or emulator. For command-line installs, use `adb install <path-to-apk>` with the intended device selected.
2. Open Aiden and pair it with a reachable OpenClaw Gateway. Follow the in-app setup for a QR code, setup code, or manual settings and approve the device on your Gateway. See [OpenClaw’s Android pairing guide](https://docs.openclaw.ai/platforms/android).
3. Select **Aiden** as the default digital assistant in Android. On a compatible Galaxy, set the Side button’s long press to open the digital assistant. Other devices may offer a gesture or a different shortcut.
4. Open the panel and tap **Dictate**. For hands-free wake on an ARM64 phone, choose **Use screen → Hey Aiden hands-free → Start listening**, then grant microphone and notification permissions. Say **“Hey Aiden”** while the phone is unlocked. The notification includes a **Stop** control.
5. Once paired, send a question and ask a follow-up in the same voice session. Aiden uses the selected Gateway agent when available and can use `aiden-fast` or the Gateway’s default agent. Supported phone commands, such as checking the battery or starting a timer, run on the phone.

The tested handset baseline is a Galaxy S24 Ultra. On-device speech recognition and an installed offline Android TTS voice are required for the voice flow. Background wake pauses on lock and may have to be started again after a reboot or force stop. Side button and screen capture behavior depend on the Android version, phone, and user settings. Screen text or images are shown for review before they are sent. Paired conversation sends the recognized words to the Gateway and synthesizes replies with Android’s installed offline voice.

## Targeted tests

From `openclaw-src/apps/android`, run:

```bash
./gradlew :app:testThirdPartyDebugUnitTest \
  --tests '*AidenAssistantPanelTest' \
  --tests '*PhoneCommandTest' \
  --tests '*PhoneQuickActionTest' \
  --tests '*PhoneUtilityActionTest' \
  --tests '*PhoneGoogleActionTest' \
  --tests '*VoiceWakeManagerTest' \
  --tests '*AndroidLicenseNoticesTest'
```

The patch retains OpenClaw’s MIT notices. Wake detection uses the upstream Apache-2.0 Sherpa-ONNX runtime and GigaSpeech keyword model. Its packaged ONNX Runtime libraries carry MIT and third-party notices. See the prepared checkout’s `apps/android/app/src/thirdPartyDebug/assets/aiden-wake/README.md` for the exact upstream assets and checksums.
