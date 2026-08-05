import { createClient } from "@supabase/supabase-js";
import {
  createValidatePlayPurchaseHandler,
  type PurchaseAuditInput,
  type PurchaseAuditResult,
} from "./handler.ts";

const auditPurchase = async (
  input: PurchaseAuditInput,
): Promise<PurchaseAuditResult> => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const backendKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !backendKey) return "configuration_error";

  const adminClient = createClient(supabaseUrl, backendKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
      detectSessionInUrl: false,
    },
  });
  const {
    data: { user },
    error: userError,
  } = await adminClient.auth.getUser(input.accessToken);
  if (userError || !user) return "unauthorized";

  const { error: auditError } = await adminClient
    .from("purchase_validation_events")
    .insert([
      {
        user_id: user.id,
        platform: input.platform,
        product_id: input.productId,
        purchase_token_hash: input.tokenHash,
        event_type: "received",
      },
      {
        user_id: user.id,
        platform: input.platform,
        product_id: input.productId,
        purchase_token_hash: input.tokenHash,
        event_type: "validation_started",
      },
      {
        user_id: user.id,
        platform: input.platform,
        product_id: input.productId,
        purchase_token_hash: input.tokenHash,
        event_type: "validation_failed",
        message: "backend_validation_not_enabled",
      },
    ]);
  return auditError ? "write_error" : "ok";
};

Deno.serve(createValidatePlayPurchaseHandler(auditPurchase));
