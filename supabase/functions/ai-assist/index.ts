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

const DEFAULT_MODEL = "gemini-2.5-flash";
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

const authenticate = async (accessToken: string) => {
  const client = adminClient();
  const { data, error } = await client.auth.getUser(accessToken);
  if (error || !data.user) return null;
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
  if (error) throw new Error("entitlement_read_failed");
  if (!data) return { isPremiumActive: false, dailyLimit: 0 };

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
  if (error) throw new Error("quota_read_failed");
  const row = Array.isArray(data) ? data[0] : data;
  if (!row || typeof row !== "object") throw new Error("quota_read_failed");
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
  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey,
        },
        signal: controller.signal,
        body: JSON.stringify({
          systemInstruction: {
            parts: [{ text: systemInstruction(request.languageCode) }],
          },
          contents: [{ role: "user", parts: [{ text: request.prompt }] }],
          generationConfig: {
            temperature: 0.2,
            responseMimeType: "application/json",
            responseSchema,
          },
        }),
      },
    );
    const latencyMs = Date.now() - startedAt;
    if (!response.ok) return { status: "failed", model, latencyMs };

    const payload = await response.json();
    const text = payload?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (typeof text !== "string") return { status: "failed", model, latencyMs };
    return { status: "ok", raw: JSON.parse(text), model, latencyMs };
  } catch {
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
