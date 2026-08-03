import { createClient } from "@supabase/supabase-js";

const jsonHeaders = {
  "Content-Type": "application/json; charset=utf-8",
};

const jsonResponse = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), { status, headers: jsonHeaders });

Deno.serve(async (request) => {
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

    // No Calcademy cloud tables exist in 1.5. Before cloud sync ships, add
    // owner-scoped cleanup (or ON DELETE CASCADE) for profiles, subscriptions,
    // usage_limits, ai_requests, and saved_cloud_items here and test it before
    // deleting the Auth user. Local-only data is intentionally device-managed.
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
