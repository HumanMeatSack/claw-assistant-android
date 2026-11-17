# Try Aiden

On a paired phone with the preview selected as the Android digital assistant, hold the Side button to open the panel. To try voice wake, tap **Use screen → Hey Aiden hands-free → Start listening**, then close the panel. Keep the phone unlocked.

## Example conversation

These are prompts to try on your setup. Live readings will come from your own Gateway.

1. Say **“Hey Aiden.”** Wait for the prompt to speak.
2. Ask **“How much free storage does the host have?”** Use the optional Gateway plugin for this check.
3. Ask **“Check that again.”** Aiden fetches a fresh reading from the same source when this route is available.
4. Ask **“Think it through. I have $36, boards cost $8 each, and shipping is $5 per order. Can I afford four?”** With local reasoning enabled, Aiden can work through the numbers. Four would cost $37, and three would cost $29.
5. Ask **“Ask Codex how the phone sends my voice request.”** With the optional Codex route enabled, the reply comes back in the same conversation. The Gateway sends the question text to Codex.
6. Say **“Stop conversation.”**

## Validation

The personal prototype verified that the Side button opened the panel, the wake phrase opened it over another app, and five transcribed handset turns had corresponding Gateway replies. It also exercised local phone utilities and the Gateway lookup and Codex routes. These observations describe the prototype. Audible playback of the newer tool and Codex replies, general device compatibility, and full away-from-home voice use need separate handset tests.

The public Android patch built successfully and passed 36 focused unit tests. The APK installed on a fresh Android 36.1 ARM64 emulator. Android selected Aiden as its default assistant, and the system Assist action opened the panel over Android’s Stopwatch. Aiden’s local battery check matched Android’s reported level. The [emulator screenshot](media/panel-emulator.png) shows that run. Testing the Samsung Side button and audio on the public build requires a handset.

The public Gateway plugin passed seven automated tests. A fresh OpenClaw 2026.9.8 instance accepted the documented setup and persisted replies to a host storage lookup, a follow-up recheck, and a Codex request with handoff disabled. The isolated test used synthetic messages with the same Gateway parameters as the Android voice panel.

Build and test the public package with the [Android guide](../android/README.md) and [Gateway guide](../gateway/README.md).
