import { statfs } from "node:fs/promises";
import { homedir, totalmem } from "node:os";
import { isAbsolute } from "node:path";
import { askCodex, reasonLocally } from "./models.mjs";

const pluginId = "aiden-voice-preview";
const supportedSession = /^(?:main|s24-voice:[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12})$/i;
const command = /^(?:aiden[,.\s]+)?(?:please\s+)?(ask codex|think (?:it|this|that) through|show (?:me )?the math)(?=$|[\s,.?!:])[\s,.?!:]*/i;
const contextReference = /^(?:(?:about|on|for)\s+)?(?:this|that|it)[.?!]*$/i;
const maxQuestionLength = 1400;

function matchRequest(text) {
  const match = command.exec(text);
  if (match) {
    return {
      kind: match[1].toLowerCase() === "ask codex" ? "codex" : "reasoning",
      question: text.slice(match[0].length).trim(),
      explain: /^show/i.test(match[1]),
    };
  }
  const plain = text.toLowerCase().replace(/[.?!]+$/, "").replace(/^aiden[,.\s]+/, "");
  if (/^(?:how much free (?:storage|disk space) (?:(?:is )?on (?:my |the )?(?:gateway|host|mac)|does (?:my |the )?(?:gateway|host|mac) have)|check gateway storage)$/.test(plain)) {
    return { kind: "storage" };
  }
  if (/^(?:how much (?:ram|memory) (?:is )?(?:installed )?on (?:my |the )?(?:gateway|mac)|check gateway memory)$/.test(plain)) {
    return { kind: "memory" };
  }
  if (plain === "check that again") return { kind: "recheck" };
}

async function recentHistory(api, sessionKey, current) {
  const { messages } = await api.runtime.subagent.getSessionMessages({ sessionKey, limit: 8 });
  return messages.filter((message) => {
    if (message?.role === "assistant") return true;
    return message?.role === "user" && (!message.provenance || message.provenance.kind === "external_user");
  }).map((message) => {
    const text = typeof message.content === "string" ? message.content
      : Array.isArray(message.content) && message.content.every((part) => part?.type === "text")
        ? message.content.map((part) => part.text).join("\n") : "";
    return { role: message.role, content: text.trim() };
  }).filter(({ content }) => content && content !== current).slice(-4)
    .map(({ role, content }) => ({ role, content: content.slice(0, 350) }));
}

export function register(api, tools = { askCodex, reasonLocally, statfs, totalmem }) {
  const settings = api.pluginConfig ?? {};
  const agentPrefix = `agent:${settings.agentId ?? "aiden-fast"}:`;
  const pending = new Map();
  const busy = new Set();

  async function answer(request, entry) {
    if (request.kind === "recheck") {
      const history = await recentHistory(api, entry.sessionKey, entry.text);
      const previous = history.findLast(({ role }) => role === "user");
      const check = previous && matchRequest(previous.content);
      if (check?.kind !== "storage" && check?.kind !== "memory") {
        return "Which host check should I run again? Ask for Gateway storage or memory.";
      }
      return answer(check, entry);
    }
    if (request.kind === "storage") {
      const storage = await tools.statfs(homedir(), { bigint: true });
      const free = (Number(storage.bavail * storage.bsize) / 2 ** 30).toFixed(1);
      return `The Gateway host has ${free} GiB available on its home filesystem.`;
    }
    if (request.kind === "memory") return `The Gateway host reports ${(tools.totalmem() / 2 ** 30).toFixed(1)} GiB of installed memory.`;
    const { kind, question, explain } = request;
    const implied = !question || contextReference.test(question);
    if (question.length > maxQuestionLength) return "Give me a shorter question.";
    if (kind === "codex" && !isAbsolute(settings.codexPath ?? "")) return "Codex handoff is disabled on this Gateway.";
    if (kind === "reasoning" && (!settings.reasoningModel || /(?:-cloud|:cloud)$/i.test(settings.reasoningModel))) {
      return "Set a locally hosted Ollama model to use extra reasoning on this Gateway.";
    }
    if (kind === "codex" && implied) return "What question would you like me to send to Codex?";
    if (busy.has(kind)) return "I’m working on another request. Try again in a moment.";

    busy.add(kind);
    try {
      if (kind === "codex") return `Codex says: ${await tools.askCodex(settings.codexPath, question)}`;
      if (!implied) return await tools.reasonLocally(settings.reasoningModel, question, []);
      const history = await recentHistory(api, entry.sessionKey, entry.text);
      if (!history.length) return "What would you like me to think through?";
      return await tools.reasonLocally(settings.reasoningModel,
        "Explain or recalculate the previous answer using the facts the user gave.", history, { explain });
    } finally {
      busy.delete(kind);
    }
  }

  api.on("before_dispatch", (event) => {
    if (event.channel !== "webchat" || event.isGroup || typeof event.messageId !== "string" ||
      typeof event.content !== "string" || typeof event.sessionKey !== "string" || !event.sessionKey.startsWith(agentPrefix) ||
      !supportedSession.test(event.sessionKey.slice(agentPrefix.length))) return;

    const text = event.content.trim();
    const request = matchRequest(text);
    if (!request || pending.has(event.messageId) || pending.size >= 128) return;
    const expire = setTimeout(() => pending.delete(event.messageId), 60_000).unref();
    pending.set(event.messageId, { sessionKey: event.sessionKey, text, request, expire });
  });

  // Handle the matched request after OpenClaw initializes the session so the
  // reply is stored even if this is the first turn.
  api.on("before_agent_reply", async (_event, context) => {
    const entry = pending.get(context.runId);
    if (!entry || entry.sessionKey !== context.sessionKey) return;
    pending.delete(context.runId);
    clearTimeout(entry.expire);
    try {
      return { handled: true, reply: { text: await answer(entry.request, entry) } };
    } catch {
      api.logger.warn(`Aiden preview request failed (${entry.request.kind})`);
      return { handled: true, reply: { text: "I couldn’t complete that check just now." } };
    }
  }, { eligibleTriggers: ["user"] });
}

export default { id: pluginId, register };
