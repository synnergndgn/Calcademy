import { assertEquals } from "@std/assert";
import { sanitizePlan, validateRequest } from "./contract.ts";
import {
  type AssistantDependencies,
  type AssistantEvent,
  createAiAssistHandler,
} from "./handler.ts";

const post = (body: unknown, authorization = "Bearer token") =>
  new Request("https://example.test/ai-assist", {
    method: "POST",
    headers: {
      Authorization: authorization,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

const validBody = { prompt: "Solve 2x + 3 = 9", languageCode: "en" };

const goodPlan = {
  intent: "equationSolving",
  summary: "Use the equation solver.",
  steps: ["Enter the equation.", "Read the root."],
  toolIds: ["equation_solver"],
  formulaIds: ["quadratic-formula"],
};

type Overrides = Partial<AssistantDependencies>;

const makeDependencies = (overrides: Overrides = {}) => {
  const events: AssistantEvent[] = [];
  const releases: string[] = [];
  const dependencies: AssistantDependencies = {
    authenticate: () => Promise.resolve({ id: "user-1" }),
    readEntitlement: () =>
      Promise.resolve({ isPremiumActive: true, dailyLimit: 20 }),
    consumeQuota: () =>
      Promise.resolve({
        allowed: true,
        used: 1,
        limit: 20,
        resetsAt: "2026-08-06T00:00:00Z",
      }),
    releaseQuota: (userId: string) => {
      releases.push(userId);
      return Promise.resolve();
    },
    callProvider: () =>
      Promise.resolve({
        status: "ok" as const,
        raw: goodPlan,
        model: "test-model",
        latencyMs: 5,
      }),
    recordEvent: (event: AssistantEvent) => {
      events.push(event);
      return Promise.resolve();
    },
    ...overrides,
  };
  return { dependencies, events, releases };
};

Deno.test("OPTIONS returns 204 with CORS headers", async () => {
  const { dependencies } = makeDependencies();
  const response = await createAiAssistHandler(dependencies)(
    new Request("https://example.test/ai-assist", { method: "OPTIONS" }),
  );
  assertEquals(response.status, 204);
  assertEquals(response.headers.get("Access-Control-Allow-Origin"), "*");
});

Deno.test("non-POST is rejected", async () => {
  const { dependencies } = makeDependencies();
  const response = await createAiAssistHandler(dependencies)(
    new Request("https://example.test/ai-assist", { method: "GET" }),
  );
  assertEquals(response.status, 405);
});

Deno.test("missing bearer authentication is rejected", async () => {
  const { dependencies } = makeDependencies();
  const response = await createAiAssistHandler(dependencies)(
    new Request("https://example.test/ai-assist", {
      method: "POST",
      body: JSON.stringify(validBody),
    }),
  );
  assertEquals(response.status, 401);
});

Deno.test("an unknown language code is rejected", async () => {
  const { dependencies } = makeDependencies();
  const response = await createAiAssistHandler(dependencies)(
    post({ prompt: "hello", languageCode: "de" }),
  );
  assertEquals(response.status, 400);
});

Deno.test("input over the character limit is rejected", async () => {
  const { dependencies } = makeDependencies();
  const response = await createAiAssistHandler(dependencies)(
    post({ prompt: "x".repeat(1001), languageCode: "en" }),
  );
  assertEquals(response.status, 400);
  assertEquals((await response.json()).error, "input_too_long");
});

Deno.test("a free account never reaches the provider", async () => {
  let providerCalls = 0;
  const { dependencies, events } = makeDependencies({
    readEntitlement: () =>
      Promise.resolve({ isPremiumActive: false, dailyLimit: 0 }),
    callProvider: () => {
      providerCalls += 1;
      return Promise.resolve({
        status: "ok" as const,
        raw: goodPlan,
        model: "test-model",
        latencyMs: 1,
      });
    },
  });
  const response = await createAiAssistHandler(dependencies)(post(validBody));
  assertEquals(response.status, 403);
  assertEquals((await response.json()).error, "premium_required");
  assertEquals(providerCalls, 0);
  assertEquals(
    events.some((event) => event.eventType === "entitlement_denied"),
    true,
  );
});

Deno.test("an exhausted quota never reaches the provider", async () => {
  let providerCalls = 0;
  const { dependencies } = makeDependencies({
    consumeQuota: () =>
      Promise.resolve({
        allowed: false,
        used: 20,
        limit: 20,
        resetsAt: "2026-08-06T00:00:00Z",
      }),
    callProvider: () => {
      providerCalls += 1;
      return Promise.resolve({
        status: "ok" as const,
        raw: goodPlan,
        model: "test-model",
        latencyMs: 1,
      });
    },
  });
  const response = await createAiAssistHandler(dependencies)(post(validBody));
  assertEquals(response.status, 429);
  const body = await response.json();
  assertEquals(body.error, "quota_exceeded");
  assertEquals(body.quota.used, 20);
  assertEquals(providerCalls, 0);
});

Deno.test("a provider failure refunds the reserved quota unit", async () => {
  const { dependencies, releases } = makeDependencies({
    callProvider: () =>
      Promise.resolve({
        status: "failed" as const,
        model: "test-model",
        latencyMs: 12,
      }),
  });
  const response = await createAiAssistHandler(dependencies)(post(validBody));
  assertEquals(response.status, 502);
  assertEquals(releases, ["user-1"]);
});

Deno.test("an unusable provider response refunds and fails closed", async () => {
  const { dependencies, releases } = makeDependencies({
    callProvider: () =>
      Promise.resolve({
        status: "ok" as const,
        raw: { intent: "equationSolving", summary: "" },
        model: "test-model",
        latencyMs: 3,
      }),
  });
  const response = await createAiAssistHandler(dependencies)(post(validBody));
  assertEquals(response.status, 502);
  assertEquals(releases, ["user-1"]);
});

Deno.test("a valid request returns the sanitized plan and quota", async () => {
  const { dependencies, events } = makeDependencies();
  const response = await createAiAssistHandler(dependencies)(post(validBody));
  assertEquals(response.status, 200);
  const body = await response.json();
  assertEquals(body.success, true);
  assertEquals(body.intent, "equationSolving");
  assertEquals(body.toolIds, ["equation_solver"]);
  assertEquals(body.quota.limit, 20);
  assertEquals(
    events.some((event) => event.eventType === "response_returned"),
    true,
  );
});

Deno.test("no audit event carries prompt text or model output", async () => {
  const { dependencies, events } = makeDependencies();
  await createAiAssistHandler(dependencies)(post(validBody));
  const serialized = JSON.stringify(events);
  assertEquals(serialized.includes("Solve 2x + 3 = 9"), false);
  assertEquals(serialized.includes("Use the equation solver."), false);
});

Deno.test("an audit write failure does not fail the request", async () => {
  const { dependencies } = makeDependencies({
    recordEvent: () => Promise.reject(new Error("audit down")),
  });
  const response = await createAiAssistHandler(dependencies)(post(validBody));
  assertEquals(response.status, 200);
});

Deno.test("unknown tool IDs are dropped from model output", () => {
  const plan = sanitizePlan({
    ...goodPlan,
    toolIds: ["equation_solver", "shell_exec", "../../admin"],
  });
  assertEquals(plan?.toolIds, ["equation_solver"]);
});

Deno.test("an unknown intent collapses to unsupported", () => {
  const plan = sanitizePlan({ ...goodPlan, intent: "jailbreak" });
  assertEquals(plan?.intent, "unsupported");
});

Deno.test("out-of-scope plans carry no tool or formula suggestions", () => {
  const plan = sanitizePlan({ ...goodPlan, intent: "outOfScope" });
  assertEquals(plan?.toolIds, []);
  assertEquals(plan?.formulaIds, []);
  assertEquals(plan?.steps, []);
});

Deno.test("formula IDs that are not plain identifiers are dropped", () => {
  const plan = sanitizePlan({
    ...goodPlan,
    formulaIds: [
      "quadratic-formula",
      "https://evil.test",
      "../secrets",
      "net_present_value",
      "A".repeat(80),
    ],
  });
  assertEquals(plan?.formulaIds, ["quadratic-formula"]);
});

Deno.test("oversized summaries and step lists are capped", () => {
  const plan = sanitizePlan({
    ...goodPlan,
    summary: "s".repeat(5000),
    steps: Array.from({ length: 40 }, () => "t".repeat(900)),
  });
  assertEquals(plan?.summary.length, 1200);
  assertEquals(plan?.steps.length, 8);
  assertEquals(plan?.steps[0].length, 400);
});

Deno.test("finance intent is flagged so the client can show the disclaimer", () => {
  const plan = sanitizePlan({ ...goodPlan, intent: "finance" });
  assertEquals(plan?.isFinancial, true);
});

Deno.test("a whitespace-only prompt is rejected", () => {
  const result = validateRequest({ prompt: "   ", languageCode: "tr" });
  assertEquals(result.ok, false);
});
