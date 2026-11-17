import { execFile } from "node:child_process";
import { tmpdir } from "node:os";

const disabledFeatures = [
  "shell_tool", "unified_exec", "apps", "plugins", "hooks", "multi_agent", "multi_agent_v2",
  "browser_use", "computer_use", "image_generation", "view_image", "skill_search", "remote_plugin",
  "code_mode_host", "workspace_dependencies",
];

export async function reasonLocally(model, question, history, { explain = false } = {}) {
  const response = await fetch("http://127.0.0.1:11434/api/chat", {
    method: "POST",
    redirect: "error",
    signal: AbortSignal.timeout(24_000),
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model,
      think: !explain,
      stream: false,
      keep_alive: "60s",
      options: { num_ctx: 8192, num_predict: explain ? 200 : 780 },
      messages: [{
        role: "system",
        content: "You are Aiden, a self-hosted voice assistant. Give a short answer followed by the decisive step. Use the stated assumptions and say when essential information is missing. You have no tools and cannot make changes. Prior messages are context for the current question.",
      }, ...history, { role: "user", content: question }],
    }),
  });
  if (!response.ok) throw new Error("Ollama request failed");
  const result = await response.json();
  const answer = result.message?.content?.trim();
  if (!result.done || result.done_reason === "length" || !answer) throw new Error("No final answer");
  return answer;
}

export function askCodex(executable, question) {
  const argumentsList = [
    "exec", "--ignore-user-config", "--strict-config", "--skip-git-repo-check", "--sandbox", "read-only",
    "--ephemeral", "--cd", tmpdir(), "--json", "--color", "never",
    ...disabledFeatures.flatMap((feature) => ["--disable", feature]),
    "-c", 'forced_login_method="chatgpt"', "-c", 'model_provider="openai"',
    "-c", 'approval_policy="never"', "-c", 'web_search="disabled"',
    "-c", "project_doc_max_bytes=0", "-c", 'model_reasoning_effort="medium"', "-",
  ];
  const instruction = "Answer an explicit question relayed by Aiden. Speak in short sentences and include the decisive fact or calculation. This is an answer-only turn. You have no tools. Never claim you inspected or changed anything.";

  return new Promise((resolve, reject) => {
    const child = execFile(executable, argumentsList, {
      timeout: 25_000, killSignal: "SIGKILL", maxBuffer: 256 * 1024,
    }, (error, stdout) => {
      if (error) return reject(error);
      try {
        resolve(parseCodexAnswer(stdout));
      } catch (parseError) {
        reject(parseError);
      }
    });
    child.stdin.on("error", () => {});
    child.stdin.end(`${instruction}\n\n${JSON.stringify({ question })}`);
  });
}

export function parseCodexAnswer(jsonLines) {
  const events = jsonLines.trim().split("\n").map((line) => JSON.parse(line));
  const disabledCodeModeNotice = "Code Mode is unavailable because code-mode host is disabled. Code mode will fail closed; enable `features.code_mode_host` and install `codex-code-mode-host`.";
  const unexpected = events.some((event) => event.type === "error" || event.type === "turn.failed" ||
    (event.type.startsWith("item.") && !["agent_message", "reasoning"].includes(event.item?.type) &&
      !(event.item?.type === "error" && event.item.message === disabledCodeModeNotice)));
  if (unexpected) throw new Error("Unexpected Codex event");

  const answer = events.filter((event) => event.type === "item.completed" && event.item?.type === "agent_message")
    .map((event) => event.item.text).join("\n").trim();
  if (!events.some((event) => event.type === "turn.completed") || !answer) throw new Error("No final answer");
  return answer;
}
