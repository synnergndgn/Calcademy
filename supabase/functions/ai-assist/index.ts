import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import {
  type AssistantRequest,
  responseSchema,
  systemInstruction,
} from "./contract.ts";
import {
  type AssistantDependencies,
  type AssistantEvent,
  createAiAssistHandler,
  type EntitlementDecision,
  FEATURE,
  type ProviderOutcome,
  type QuotaDecision,
} from "./handler.ts";

/// Daily request allowance for an account with active Premium. Mirrors
/// `LocalUsageLimitService` in the Flutter app; the value enforced is this one.
const PREMIUM_DAILY_LIMIT = 20;

/// Google retires model IDs on a schedule, and a retired ID returns 404 that
/// this function reports as a generic provider failure. `gemini-2.5-flash` was
/// already closed to new keys by 2026-08. Override with the `GEMINI_MODEL`
/// secret rather than editing this when a newer one ships.
const DEFAULT_MODEL = "gemini-3.6-flash";
const PROVIDER_TIMEOUT_MS = 20000;

const adminClient = (): SupabaseClient => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const backendKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !backendKey) {
    throw new Error("server_configuration_error");
  }
  return createClient(supabaseUrl, backendKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
      detectSessionInUrl: false,
    },
  });
};

/// Diagnostics for the paths that would otherwise return a bare 500. The
/// client renders every 500 as "unreachable", which is indistinguishable from
/// a provider outage without these. Codes and messages only — never a token,
/// a key, or prompt text.
const logFailure = (stage: string, error: unknown) => {
  const detail = error instanceof Error ? error.message : "unknown";
  console.error(`backend_error stage=${stage} detail=${detail.slice(0, 300)}`);
};

const authenticate = async (accessToken: string) => {
  const client = adminClient();
  const { data, error } = await client.auth.getUser(accessToken);
  if (error || !data.user) {
    console.error(`auth_rejected code=${error?.code ?? "no_user"}`);
    return null;
  }
  return { id: data.user.id };
};

const readEntitlement = async (
  userId: string,
): Promise<EntitlementDecision> => {
  const client = adminClient();
  const { data, error } = await client
    .from("premium_entitlements")
    .select("status, current_period_end")
    .eq("user_id", userId)
    .maybeSingle();
  if (error) {
    logFailure("entitlement_read", error);
    throw new Error("entitlement_read_failed");
  }
  if (!data) {
    console.error("entitlement_missing: no row for caller");
    return { isPremiumActive: false, dailyLimit: 0 };
  }

  const status = typeof data.status === "string" ? data.status : "inactive";
  // A null period end means "no expiry", matching get_my_premium_status(). An
  // unparseable one fails closed.
  let withinPeriod: boolean;
  if (typeof data.current_period_end !== "string") {
    withinPeriod = data.current_period_end === null;
  } else {
    const periodEnd = Date.parse(data.current_period_end);
    withinPeriod = !Number.isNaN(periodEnd) && periodEnd > Date.now();
  }
  const isPremiumActive = (status === "active" || status === "grace_period") &&
    withinPeriod;

  if (!isPremiumActive) {
    console.error(
      `entitlement_inactive status=${status} withinPeriod=${withinPeriod}`,
    );
  }

  return {
    isPremiumActive,
    dailyLimit: isPremiumActive ? PREMIUM_DAILY_LIMIT : 0,
  };
};

const consumeQuota = async (
  userId: string,
  limit: number,
): Promise<QuotaDecision> => {
  const client = adminClient();
  const { data, error } = await client.rpc("consume_ai_usage_quota", {
    p_user_id: userId,
    p_feature: FEATURE,
    p_limit: limit,
  });
  if (error) {
    logFailure("quota_consume", error);
    throw new Error("quota_read_failed");
  }
  const row = Array.isArray(data) ? data[0] : data;
  if (!row || typeof row !== "object") {
    console.error("quota_consume_empty: rpc returned no row");
    throw new Error("quota_read_failed");
  }
  const record = row as Record<string, unknown>;
  return {
    allowed: record.allowed === true,
    used: typeof record.used_count === "number" ? record.used_count : 0,
    limit: typeof record.limit_count === "number" ? record.limit_count : limit,
    resetsAt: typeof record.period_end === "string"
      ? record.period_end
      : new Date().toISOString(),
  };
};

const releaseQuota = async (userId: string) => {
  const client = adminClient();
  const { error } = await client.rpc("release_ai_usage_quota", {
    p_user_id: userId,
    p_feature: FEATURE,
  });
  if (error) throw new Error("quota_release_failed");
};

const recordEvent = async (event: AssistantEvent) => {
  const client = adminClient();
  await client.from("ai_assistant_events").insert({
    user_id: event.userId,
    feature: FEATURE,
    event_type: event.eventType,
    model: event.model ?? null,
    intent: event.intent ?? null,
    input_characters: event.inputCharacters ?? null,
    output_characters: event.outputCharacters ?? null,
    latency_ms: event.latencyMs ?? null,
    reason: event.reason ?? null,
  });
};

/// Measured on staging: thinking tokens ran ~2.7x the visible answer and made
/// up roughly two thirds of the billable output. Picking a tool and writing
/// three steps does not need that depth. Gemini 3 Flash cannot turn thinking
/// off, only lower it.
const THINKING_LEVEL = Deno.env.get("GEMINI_THINKING_LEVEL") ?? "low";

const buildRequestBody = (
  request: AssistantRequest,
  withThinkingLevel: boolean,
) => ({
  systemInstruction: {
    parts: [{ text: systemInstruction(request.languageCode) }],
  },
  contents: [{ role: "user", parts: [{ text: request.prompt }] }],
  generationConfig: {
    temperature: 0.2,
    responseMimeType: "application/json",
    responseSchema,
    ...(withThinkingLevel ? { thinkingLevel: THINKING_LEVEL } : {}),
  },
});

/// Calls Gemini with the API key held only in this function's environment.
/// The user's text is sent as its own turn so it cannot merge into the system
/// instruction, and the reply is constrained to the shared response schema.
const callProvider = async (
  request: AssistantRequest,
): Promise<ProviderOutcome> => {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  const model = Deno.env.get("GEMINI_MODEL") ?? DEFAULT_MODEL;
  const startedAt = Date.now();
  if (!apiKey) return { status: "failed", model, latencyMs: 0 };

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), PROVIDER_TIMEOUT_MS);
  const send = (withThinkingLevel: boolean) =>
    fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey,
        },
        signal: controller.signal,
        body: JSON.stringify(buildRequestBody(request, withThinkingLevel)),
      },
    );

  try {
    let response = await send(true);
    if (response.status === 400) {
      // The exact spelling of the thinking field is version-dependent, and a
      // rejected field would take the whole feature down for a cost tweak.
      // Retry once without it: worst case we pay for full thinking, which is
      // what we did before, rather than dropping to local mode.
      console.warn(
        "gemini_thinking_level_rejected: retrying without thinkingLevel",
      );
      response = await send(false);
    }
    const latencyMs = Date.now() - startedAt;
    if (!response.ok) {
      // The upstream error body carries the actual reason — a bad model ID, a
      // rejected schema, a quota problem. It contains no prompt text and no
      // key, so it is safe to log and is the only way to tell these apart.
      const detail = await response.text().catch(() => "");
      console.error(
        `gemini_http_error status=${response.status} model=${model} detail=${
          detail.slice(0, 600)
        }`,
      );
      return { status: "failed", model, latencyMs };
    }

    const payload = await response.json();
    const text = payload?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (typeof text !== "string") {
      // Usually a safety block or a truncated candidate. Log the finish reason
      // and prompt feedback only — never the candidate text.
      console.error(
        `gemini_empty_candidate model=${model} finishReason=${
          payload?.candidates?.[0]?.finishReason ?? "none"
        } blockReason=${payload?.promptFeedback?.blockReason ?? "none"}`,
      );
      return { status: "failed", model, latencyMs };
    }
    // Token counts only — no prompt, no answer. This is what makes the real
    // per-request cost measurable, and what tells us whether the thinking
    // budget is worth constraining for what is essentially a routing task.
    const usage = payload?.usageMetadata;
    console.log(
      `gemini_usage model=${model} latencyMs=${latencyMs} prompt=${
        usage?.promptTokenCount ?? "?"
      } candidates=${usage?.candidatesTokenCount ?? "?"} thoughts=${
        usage?.thoughtsTokenCount ?? 0
      } total=${usage?.totalTokenCount ?? "?"}`,
    );

    try {
      return { status: "ok", raw: JSON.parse(text), model, latencyMs };
    } catch {
      console.error(
        `gemini_unparsable_json model=${model} length=${text.length}`,
      );
      return { status: "failed", model, latencyMs };
    }
  } catch (error) {
    console.error(
      `gemini_transport_error model=${model} name=${
        error instanceof Error ? error.name : "unknown"
      }`,
    );
    return { status: "failed", model, latencyMs: Date.now() - startedAt };
  } finally {
    clearTimeout(timeout);
  }
};

const dependencies: AssistantDependencies = {
  authenticate,
  readEntitlement,
  consumeQuota,
  releaseQuota,
  callProvider,
  recordEvent,
};

Deno.serve(createAiAssistHandler(dependencies));
