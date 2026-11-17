# Gateway setup for Claw Assistant

The Android companion uses the `aiden-fast` agent on a private, authenticated OpenClaw Gateway. The example keeps routine conversation on a local Ollama model. The optional plugin adds read-only host checks and explicit requests for a second model.

## Set up the agent

Use OpenClaw Gateway **2026.9.8** (`fc23bc86`) and an Ollama server on the same host listening on `127.0.0.1:11434`. Run these commands from the `gateway` directory on that host.

```sh
ollama pull qwen3.5:latest
openclaw config patch --file ./examples/agent.patch.json --dry-run
openclaw config patch --file ./examples/agent.patch.json
openclaw config validate
```

The patch replaces the `models.providers.ollama.models` list. On an existing Gateway, merge the example model entry into your own list before applying the patch. Use your existing model ID if it differs. `ollama-local` is OpenClaw's marker for the local provider. The companion expects the agent ID `aiden-fast`. [OpenClaw Ollama setup](https://docs.openclaw.ai/providers/ollama)

Connect the phone using your authenticated Gateway address and approve its pairing request. Keep the Gateway and Ollama private. A personal LAN or a private tailnet can connect the phone to the Gateway. [OpenClaw Android pairing](https://docs.openclaw.ai/platforms/android) · [Gateway security](https://docs.openclaw.ai/gateway/security)

## Add the optional plugin

```sh
openclaw plugins install --link . --force --accept-capabilities
openclaw config patch --file ./examples/plugin.patch.json --dry-run
openclaw config patch --file ./examples/plugin.patch.json
openclaw config validate
openclaw plugins inspect aiden-voice-preview --runtime
```

Review the source before installing. `--force` acknowledges the local package source and `--accept-capabilities` accepts the plugin’s detected capabilities. A linked install expects this directory to stay where it is.

| Say | Result |
| --- | --- |
| **Check gateway storage** | Available space on the Gateway account's home filesystem. |
| **Check gateway memory** | Installed memory on the Gateway host. |
| **Check that again** | A fresh host reading after a storage or memory question. |
| **Think it through.** Then ask a question. | An answer from your configured local reasoning model. |
| **Show me the math** | An explanation based on recent messages in the same session. |
| **Ask Codex.** Then state a specific question. | An answer-only Codex turn when the handoff is enabled. |

Local reasoning and Codex handoff start disabled. Enable local reasoning with a reasoning-capable model hosted by your local Ollama, such as the following.

```sh
ollama pull qwen3:14b
openclaw config set plugins.entries.aiden-voice-preview.config.reasoningModel qwen3:14b
```

To enable Codex handoff, install Codex CLI, sign in with ChatGPT as the Gateway account, and put its absolute executable path in `plugins.entries.aiden-voice-preview.config.codexPath`. The integration targets Codex CLI **0.154.0** with its answer-only flags. A newer CLI may require an update if those flags change.

## Data and access

The plugin targets an authenticated, single-owner Gateway. It matches the configured agent's direct `webchat` sessions, including the phone's `s24-voice` sessions. The session key limits routing. OpenClaw handles authentication and pairing.

The plugin uses conversation hooks to recognize requests. Local explanation can read up to four bounded text messages from that session. The Codex route passes only the explicitly requested question to the Codex CLI. Opting into it uses OpenAI for that answer. Host checks read filesystem or memory information and never run shell commands.

## Verify

Run `npm test` or `node --test` from this directory for routing, read-only checks, and mocked model tests. The tests send no model requests. Test recognition and spoken playback separately on the paired handset.
