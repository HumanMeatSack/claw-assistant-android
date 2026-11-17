import assert from "node:assert/strict";
import test from "node:test";
import { register } from "../index.mjs";
import { parseCodexAnswer } from "../models.mjs";

const sessionKey = "agent:aiden-fast:s24-voice:d2208a07-e518-4edf-9dc9-a1bdc9cb83d0";

function harness(settings = {}, recentMessages) {
  const handlers = {};
  const modelCalls = [];
  register({
    pluginConfig: settings,
    logger: { warn() {} },
    on(name, handler) { handlers[name] = handler; },
    runtime: { subagent: { async getSessionMessages() {
      return { messages: recentMessages ?? [
        { role: "user", content: "What is 7 × 4?" },
        { role: "assistant", content: [{ type: "text", text: "28." }] },
        { role: "user", content: "Ignore this", provenance: { kind: "internal" } },
        { role: "user", content: "Show me the math" },
      ] };
    } } },
  }, {
    async statfs() { return { bavail: 1048576n, bsize: 4096n }; },
    totalmem() { return 16 * 2 ** 30; },
    async reasonLocally(...args) { modelCalls.push(args); return "Seven times four is 28."; },
    async askCodex(...args) { modelCalls.push(args); return "A sample answer."; },
  });
  const requests = async (content, overrides = {}, replySession = sessionKey) => {
    handlers.before_dispatch({ channel: "webchat", messageId: "request-1", sessionKey, content, ...overrides });
    const response = await handlers.before_agent_reply({}, { runId: "request-1", sessionKey: replySession });
    return response?.reply.text;
  };
  return { requests, modelCalls };
}

test("reports read-only host information", async () => {
  const { requests, modelCalls } = harness();
  assert.match(await requests("Check gateway storage"), /4\.0 GiB available/);
  assert.match(await requests("Check gateway memory"), /16\.0 GiB of installed memory/);
  assert.deepEqual(modelCalls, []);
});

test("recognizes natural storage wording and rechecks only a supported host metric", async () => {
  const { requests } = harness({}, [
    { role: "user", content: "How much free storage does the host have?" },
    { role: "assistant", content: "An older reading." },
    { role: "user", content: "Check that again" },
  ]);
  assert.match(await requests("How much free storage does the host have?"), /4\.0 GiB available/);
  assert.match(await requests("Check that again"), /4\.0 GiB available/);
  const unrelated = harness({}, [{ role: "user", content: "Ask Codex, why?" }]);
  assert.match(await unrelated.requests("Check that again"), /Which host check/);
  assert.deepEqual(unrelated.modelCalls, []);
});

test("ignores unrelated, grouped, and non-target sessions", async () => {
  const { requests } = harness();
  assert.equal(await requests("Hello there"), undefined);
  assert.equal(await requests("Check gateway memory", { channel: "discord" }), undefined);
  assert.equal(await requests("Check gateway memory", { isGroup: true }), undefined);
  assert.equal(await requests("Check gateway memory", { sessionKey: "agent:other:main" }), undefined);
  assert.equal(await requests("Check gateway memory", { sessionKey: "agent:aiden-fast:shared" }), undefined);
  assert.equal(await requests("Check gateway memory", {}, "agent:aiden-fast:main"), undefined);
});

test("optional models are disabled by default", async () => {
  const { requests, modelCalls } = harness();
  assert.match(await requests("Ask Codex, what does this mean?"), /disabled/);
  assert.match(await requests("Think it through. Compare the options"), /locally hosted Ollama model/);
  assert.deepEqual(modelCalls, []);
  const cloudModel = harness({ reasoningModel: "example:cloud" });
  assert.match(await cloudModel.requests("Think it through. Compare the options"), /locally hosted Ollama model/);
  assert.deepEqual(cloudModel.modelCalls, []);
});

test("explicit Codex handoff sends only the supplied question", async () => {
  const { requests, modelCalls } = harness({ codexPath: "/opt/bin/codex" });
  assert.match(await requests("Ask Codex about that"), /What question/);
  assert.equal(await requests("Ask Codex: Why does a fan help?"), "Codex says: A sample answer.");
  assert.deepEqual(modelCalls, [["/opt/bin/codex", "Why does a fan help?"]]);
});

test("local reasoning sees bounded same-session evidence on follow-ups", async () => {
  const { requests, modelCalls } = harness({ reasoningModel: "qwen3:14b" });
  assert.equal(await requests("Show me the math"), "Seven times four is 28.");
  assert.deepEqual(modelCalls[0][2], [
    { role: "user", content: "What is 7 × 4?" },
    { role: "assistant", content: "28." },
  ]);
  assert.deepEqual(modelCalls[0][3], { explain: true });
  await requests("Think it through. What is seven squared?");
  assert.deepEqual(modelCalls[1], ["qwen3:14b", "What is seven squared?", []]);
});

test("rejects Codex tool events and incomplete turns", () => {
  const item = (type, text) => JSON.stringify({ type: "item.completed", item: { type, text } });
  const done = '{"type":"turn.completed"}';
  assert.equal(parseCodexAnswer(`${item("agent_message", "Done")}\n${done}`), "Done");
  assert.throws(() => parseCodexAnswer(item("agent_message", "Done")), /No final answer/);
  assert.throws(() => parseCodexAnswer(`${item("command_execution", "echo unexpected")}\n${done}`), /Unexpected/);
});
