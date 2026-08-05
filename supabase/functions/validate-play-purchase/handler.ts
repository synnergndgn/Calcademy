export type PurchaseAuditInput = {
  accessToken: string;
  productId: string;
  platform: "google_play";
  tokenHash: string;
};

export type PurchaseAuditResult =
  | "ok"
  | "unauthorized"
  | "configuration_error"
  | "write_error";

export type PurchaseAuditor = (
  input: PurchaseAuditInput,
) => Promise<PurchaseAuditResult>;

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

const sha256 = async (value: string) => {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
};

export const createValidatePlayPurchaseHandler =
  (auditPurchase: PurchaseAuditor) => async (request: Request) => {
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

    let body: Record<string, unknown>;
    try {
      body = await request.json();
    } catch {
      return jsonResponse(400, { error: "invalid_body" });
    }
    const productId = body.productId;
    const token = body.purchaseToken;
    const platform = body.platform;
    if (
      typeof productId !== "string" ||
      productId.trim().length === 0 ||
      typeof token !== "string" ||
      token.trim().length === 0 ||
      platform !== "google_play"
    ) {
      return jsonResponse(400, { error: "invalid_body" });
    }

    try {
      const auditResult = await auditPurchase({
        accessToken,
        productId: productId.trim(),
        platform,
        tokenHash: await sha256(token),
      });
      if (auditResult === "unauthorized") {
        return jsonResponse(401, { error: "authentication_required" });
      }
      if (auditResult === "configuration_error") {
        return jsonResponse(500, { error: "server_configuration_error" });
      }
      if (auditResult === "write_error") {
        return jsonResponse(500, { error: "audit_write_failed" });
      }
      return jsonResponse(200, {
        success: false,
        status: "unsupported",
        message: "Backend validation is not enabled yet.",
      });
    } catch {
      return jsonResponse(500, { error: "validation_request_failed" });
    }
  };
