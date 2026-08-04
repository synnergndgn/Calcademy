import { createClient } from "@supabase/supabase-js";

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

Deno.serve(async (request) => {
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

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse(500, { error: "server_configuration_error" });
  }

  try {
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
        detectSessionInUrl: false,
      },
    });

    // Resolve the caller on the Auth server. Never accept a user ID from the
    // request body or trust user-editable metadata for authorization.
    const {
      data: { user },
      error: userError,
    } = await adminClient.auth.getUser(accessToken);
    if (userError || !user) {
      return jsonResponse(401, { error: "authentication_required" });
    }

    // Calcademy's 1.7 profile, entitlement, purchase, validation-event, and
    // quota foreign keys use ON DELETE CASCADE. Local Saved data remains
    // intentionally device-managed and is not available to this function.
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(
      user.id,
    );
    if (deleteError) {
      return jsonResponse(500, { error: "account_deletion_failed" });
    }

    return jsonResponse(200, { success: true });
  } catch {
    return jsonResponse(500, { error: "account_deletion_failed" });
  }
});
