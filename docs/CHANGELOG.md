# Changelog

## Current source preview

- Added imported Qwen3-4B phone-local conversation using the LiteRT GPU backend. Size and SHA-256 verification precede activation; no Qwen weights are bundled.
- Added bundled Parakeet English offline recognition with Silero VAD.
- Connected Side-button, wake, and microphone entry to continuous conversation, with bounded microphone admission and explicit local failures.
- Added typed local replies, short panel context, compact tappable links, and validated phone tools. Sensitive-message and screen/image review paths remain.
- Preserved optional Gateway conversation and explicit Codex delegation with bounded visible call context. Home Assistant/web lookup-control backends are not bundled.
- Kept offline Android TTS as the live-panel default. Optional Alba uses PCM16 streaming and content-free playback diagnostics. This is a compatibility trial, not proof that the previous float format was invalid.
- Current public build/test receipts are tracked in [demo.md](demo.md), separately from private development observations.

## v0.1.0 — original preview

- Published a pinned OpenClaw Android patch with Side-button panel, user-armed wake, phone utilities, and Gateway conversation.
- Recorded 36 focused Android tests and an emulator battery demo.
- Included an optional Gateway plugin for host checks, local reasoning, and explicit Codex routing.
