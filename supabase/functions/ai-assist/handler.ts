import {
  type AssistantPlan,
  type AssistantRequest,
  sanitizePlan,
  validateRequest,
} from "./contract.ts";

export const FEATURE = "gemini_assistant";

export type AuthenticatedUser = { id: string };

export type EntitlementDecision = {
  isPremiumActive: boolean;
  dailyLimit: number;
};

export type QuotaDecision = {
  allowed: boolean;
  used: number;
  limit: number;
  resetsAt: string;
};

export type ProviderOutcome =
  | { status: "ok"; raw: unknown; model: string; latencyMs: number }
  | { status: "failed"; model: string; latencyMs: number };

export type AssistantEvent = {
  userId: string | null;
  eventType:
    | "request_received"
    | "input_rejected"
    | "entitlement_denied"
    | "quota_denied"
    | "provider_called"
    | "provider_failed"
    | "response_returned"
    | "response_rejected";
  model?: string;
  intent?: string;
  inputCharacters?: number;
  outputCharacters?: number;
  latencyMs?: number;
  reason?: string;
};

export type AssistantDependencies = {
  authenticate: (accessToken: string) => Promise<AuthenticatedUser | null>;
  readEntitlement: (userId: string) => Promise<EntitlementDecision>;
  consumeQuota: (userId: string, limit: number) => Promise<QuotaDecision>;
  releaseQuota: (userId: string) => Promise<void>;
  callProvider: (request: AssistantRequest) => Promise<ProviderOutcome>;
  recordEvent: (event: AssistantEvent) => Promise<void>;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const jsonHeaders = {
  ...corsHeaders,
  "Content-Type": "application/json; charset=utf-8",
};

const jsonResponse = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), { status, headers: jsonHeaders });

const planCharacters = (plan: AssistantPlan) =>
  plan.summary.length +
  plan.steps.reduce((total, step) => total + step.length, 0);

/// Audit writes must never be able to fail the user's request, and must never
/// carry prompt text or model output — only the counts recorded here.
const safeRecord = async (
  dependencies: AssistantDependencies,
  event: AssistantEvent,
) => {
  try {
    await dependencies.recordEvent(event);
  } catch {
    // Intentionally ignored.
  }
};

export const createAiAssistHandler =
  (dependencies: AssistantDependencies) => async (request: Request) => {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }
    if (request.method !== "POST") {
      return jsonResponse(405, { error: "method_not_allowed" });
    }

    const authorization = request.headers.get("Authorization");
    if (!authorization?.startsWith("Bearer ")) {
      return jsonResponse(401, { error: "authentication_required" });
    }
    const accessToken = authorization.slice("Bearer ".length).trim();
    if (accessToken.length === 0) {
      return jsonResponse(401, { error: "authentication_required" });
    }

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return jsonResponse(400, { error: "invalid_body" });
    }

    const validation = validateRequest(body);
    if (!validation.ok) {
      return jsonResponse(400, { error: validation.reason });
    }
    const assistantRequest = validation.value;

    let user: AuthenticatedUser | null;
    try {
      user = await dependencies.authenticate(accessToken);
    } catch {
      return jsonResponse(500, { error: "server_configuration_error" });
    }
    if (!user) {
      return jsonResponse(401, { error: "authentication_required" });
    }

    await safeRecord(dependencies, {
      userId: user.id,
      eventType: "request_received",
      inputCharacters: assistantRequest.prompt.length,
    });

    let entitlement: EntitlementDecision;
    try {
      entitlement = await dependencies.readEntitlement(user.id);
    } catch {
      return jsonResponse(500, { error: "server_configuration_error" });
    }
    if (!entitlement.isPremiumActive || entitlement.dailyLimit <= 0) {
      await safeRecord(dependencies, {
        userId: user.id,
        eventType: "entitlement_denied",
        reason: "premium_required",
      });
      return jsonResponse(403, { error: "premium_required" });
    }

    // Reserve quota before the provider call so concurrent requests cannot
    // both pass the check and then both spend a unit.
    let quota: QuotaDecision;
    try {
      quota = await dependencies.consumeQuota(user.id, entitlement.dailyLimit);
    } catch {
      return jsonResponse(500, { error: "server_configuration_error" });
    }
    if (!quota.allowed) {
      await safeRecord(dependencies, {
        userId: user.id,
        eventType: "quota_denied",
        reason: "daily_limit_reached",
      });
      return jsonResponse(429, {
        error: "quota_exceeded",
        quota: {
          used: quota.used,
          limit: quota.limit,
          resetsAt: quota.resetsAt,
        },
      });
    }

    let outcome: ProviderOutcome;
    try {
      outcome = await dependencies.callProvider(assistantRequest);
    } catch {
      outcome = { status: "failed", model: "unknown", latencyMs: 0 };
    }

    if (outcome.status === "failed") {
      // The user never received an answer, so give the reserved unit back.
      try {
        await dependencies.releaseQuota(user.id);
      } catch {
        // A failed release only costs the user one unit; never fail the
        // request twice for the same upstream outage.
      }
      await safeRecord(dependencies, {
        userId: user.id,
        eventType: "provider_failed",
        model: outcome.model,
        latencyMs: outcome.latencyMs,
        reason: "provider_unavailable",
      });
      return jsonResponse(502, { error: "provider_unavailable" });
    }

    await safeRecord(dependencies, {
      userId: user.id,
      eventType: "provider_called",
      model: outcome.model,
      latencyMs: outcome.latencyMs,
    });

    const plan = sanitizePlan(outcome.raw);
    if (!plan) {
      try {
        await dependencies.releaseQuota(user.id);
      } catch {
        // See above.
      }
      await safeRecord(dependencies, {
        userId: user.id,
        eventType: "response_rejected",
        model: outcome.model,
        reason: "unusable_provider_response",
      });
      return jsonResponse(502, { error: "provider_unavailable" });
    }

    await safeRecord(dependencies, {
      userId: user.id,
      eventType: "response_returned",
      model: outcome.model,
      intent: plan.intent,
      inputCharacters: assistantRequest.prompt.length,
      outputCharacters: planCharacters(plan),
      latencyMs: outcome.latencyMs,
    });

    return jsonResponse(200, {
      success: true,
      intent: plan.intent,
      summary: plan.summary,
      steps: plan.steps,
      toolIds: plan.toolIds,
      formulaIds: plan.formulaIds,
      isFinancial: plan.isFinancial,
      quota: {
        used: quota.used,
        limit: quota.limit,
        resetsAt: quota.resetsAt,
      },
    });
  };
