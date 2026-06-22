/**
 * PTVon proxy — a Cloudflare Worker that holds the PTV devid + key as secrets,
 * signs each request (HMAC-SHA1 of path+query), and forwards it to the PTV
 * Timetable API. The Android app calls this Worker instead of PTV directly, so
 * the key is never shipped inside the APK.
 *
 * Secrets (set with `wrangler secret put`):
 *   PTV_DEV_ID   — your numeric PTV User ID
 *   PTV_API_KEY  — your PTV API key (the signing secret)
 *
 * Usage from the app: GET https://<worker-url>/v3/departures/...?max_results=4
 * (no devid/signature needed — the Worker adds them).
 */

const PTV_BASE = "https://timetableapi.ptv.vic.gov.au";

async function signSha1(message, key) {
  const enc = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    enc.encode(key),
    { name: "HMAC", hash: "SHA-1" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", cryptoKey, enc.encode(message));
  return [...new Uint8Array(sig)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("")
    .toUpperCase();
}

export default {
  async fetch(request, env) {
    if (request.method !== "GET") {
      return new Response("Method not allowed", { status: 405 });
    }

    const url = new URL(request.url);
    // Only proxy the PTV v3 API surface.
    if (!url.pathname.startsWith("/v3/")) {
      return new Response("Not found", { status: 404 });
    }
    if (!env.PTV_DEV_ID || !env.PTV_API_KEY) {
      return new Response("Proxy not configured (missing secrets)", { status: 500 });
    }

    // Append devid, then sign path + query (PTV signs the request before `signature`).
    url.searchParams.set("devid", env.PTV_DEV_ID);
    const message = url.pathname + "?" + url.searchParams.toString();
    const signature = await signSha1(message, env.PTV_API_KEY);

    const target = `${PTV_BASE}${message}&signature=${signature}`;
    const upstream = await fetch(target, {
      headers: { "User-Agent": "PTVon-Proxy" },
      cf: { cacheTtl: 10, cacheEverything: true },
    });

    return new Response(upstream.body, {
      status: upstream.status,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Cache-Control": "public, max-age=10",
        "Access-Control-Allow-Origin": "*",
      },
    });
  },
};
