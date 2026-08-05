import { assertEquals, assertNotEquals } from "@std/assert";
import { createValidatePlayPurchaseHandler } from "./handler.ts";

const endpoint = "http://localhost/validate-play-purchase";
const handler = createValidatePlayPurchaseHandler(async () => "ok");

Deno.test("OPTIONS returns 204", async () => {
  const response = await handler(new Request(endpoint, { method: "OPTIONS" }));
  assertEquals(response.status, 204);
});

Deno.test("GET returns 405", async () => {
  const response = await handler(new Request(endpoint));
  assertEquals(response.status, 405);
});

Deno.test("POST without bearer auth returns 401", async () => {
  const response = await handler(
    new Request(endpoint, { method: "POST", body: "{}" }),
  );
  assertEquals(response.status, 401);
});

Deno.test("invalid POST body returns 400", async () => {
  const response = await handler(
    new Request(endpoint, {
      method: "POST",
      headers: {
        Authorization: "Bearer test-access-token",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ platform: "google_play" }),
    }),
  );
  assertEquals(response.status, 400);
});

Deno.test("valid request returns unsupported without echoing token", async () => {
  const secretToken = "memory-only-purchase-token";
  let capturedHash = "";
  const testHandler = createValidatePlayPurchaseHandler(async (input) => {
    capturedHash = input.tokenHash;
    return "ok";
  });
  const response = await testHandler(
    new Request(endpoint, {
      method: "POST",
      headers: {
        Authorization: "Bearer test-access-token",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        productId: "calcademy_premium_monthly",
        purchaseToken: secretToken,
        platform: "google_play",
      }),
    }),
  );
  const body = await response.text();
  assertEquals(response.status, 200);
  assertEquals(JSON.parse(body).status, "unsupported");
  assertEquals(body.includes(secretToken), false);
  assertNotEquals(capturedHash, secretToken);
  assertEquals(capturedHash.length, 64);
});
