# Try Claw Assistant for Android

Build the preview, import the verified Qwen3-4B file, enable **Use phone model**, and select Aiden as Android’s digital assistant. Use an installed offline English TTS voice, or build with optional Alba. See the [Android guide](../android/README.md).

## Phone-local walkthrough

1. Hold the Side button or use your configured assistant gesture. Wait for listening. If initial microphone handoff fails, tap the microphone once to retry.
2. Ask **“Tell me a short joke.”** After the reply, ask **“Make that shorter.”** This tests local conversation and follow-up listening, rather than just a direct utility.
3. Ask **“What is my phone’s battery level?”** Compare the result with Android. Supported exact commands can use a direct native fast path.
4. Tap the input field and type **“Explain that again.”** With local mode enabled, the answer should appear in the panel without **Review in Aiden**. Typing ends voice mode.
5. Open a fresh panel and ask **“Set a timer for five minutes.”** Check Android’s timer. Try **“Open Calculator.”** App handoff can end the panel conversation; it does not establish control of the app’s later screens.
6. Close the panel and reopen it. A new voice call starts with fresh conversation context.

For wake testing, choose **Use screen → Hey Aiden hands-free → Start listening**, close the panel, and keep the phone unlocked. Say **“Hey Aiden.”** Test without another calling/recording app using the microphone. Stop with **End conversation**, **“stop conversation,”** or the wake notification’s **Stop** action.

## Interruption and audio checks

Ask for a short story, stay quiet through its ending, then try **“Actually, tell me a joke.”** Check that playback stops, the new words are retained, and listening resumes after the answer. If someone else interrupted, try **“That was somebody else, continue.”** Recovery repeats the saved answer from its beginning.

Test the phone speaker first, then your usual headset. Interruption uses echo-cancelled communication capture; audio routes can affect results. A text-only or browser-audio test does not establish working barge-in.

For optional Alba, long-press a completed assistant message in full Chat and choose **Listen** to compare media playback with live conversation. The default build uses an installed offline Android voice. A private PCM16 Alba media trial was heard as normal and clear on an S24 Ultra phone speaker: 24 kHz, speed/pitch 1, 53,760 generated/written/rendered frames, 2,305 ms playback elapsed, and zero reported underruns. This does not establish the previous fault’s cause or validate every live route.

Record the time from the end of speech to the first useful audible answer. Keep cold model loading and warm replies separate. There is no published end-to-end latency guarantee.

## Optional Gateway walkthrough

Configure and pair your private Gateway with the [Gateway guide](../gateway/README.md). Disable phone-local mode to exercise its conversation route, or use explicit **“Ask Codex”** when that optional integration is configured.

- **“Check gateway storage.”** The optional plugin reads its host filesystem.
- **“Check that again.”** It can fetch a fresh reading after a supported host lookup.
- **“Think it through. I have $36, boards cost $8 each, and shipping is $5 per order. Can I afford four?”** With the optional reasoning model configured, four cost $37 and three cost $29.
- **“Ask Codex how this Android assistant sends a voice request.”** This uses the networked Codex integration. Typed delegation remains a review draft.

**Home Assistant and verified web search are not a bundled demo.** They need a separate implementation of the phone-agent lookup/control backend. The included host-check plugin is a different integration. Generated links, device claims, or tool labels do not prove that a live lookup occurred.

## Validation record

| Scope | Evidence |
| --- | --- |
| Current public source export | 239 focused Android tests passed with zero failures, errors, or skips; third-party debug APK assembly and Play debug Kotlin compilation passed. Seven Gateway tests passed. A fresh pinned checkout prepared with optional Alba matched all 106 patched source files, 17 model inputs, and seven AAR member contents used by the tested build. Default/optional asset verification, corrupt-input rejection, and existing-destination protection passed. Native panel renders were inspected in empty and compact-source states. No new emulator or public-package acoustic test is claimed. |
| Current private development baseline | 204 focused tests passed. Phone-local text/tool paths and a fixed PCM16 media clip were exercised on an S24 Ultra. Complete live voice quality, first-entry reliability, and end-to-end latency remain only partially verified. |
| Historical public v0.1.0 | The original public patch built and passed 36 focused Android tests. A fresh Android 36.1 ARM64 emulator selected Aiden as default assistant, opened its panel over Stopwatch, and returned a matching battery reading. The [screenshot](media/panel-emulator.png) is from that older run. |
| Historical Gateway plugin checks | Seven tests passed. An isolated OpenClaw 2026.9.8 instance accepted the setup and persisted host-check, follow-up, and disabled-Codex-route responses. These synthetic text checks did not test handset audio. |

Development-handset observations do not automatically validate the public package, its default voice, other phones, or away-from-home use. Keep build receipts separate from listening results and network-service integration tests.
