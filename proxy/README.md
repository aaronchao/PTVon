# PTVon proxy (Cloudflare Worker)

A tiny serverless proxy that keeps your PTV `devid` + key **out of the app**. The Worker
holds them as secrets, signs every request (HMAC-SHA1), and forwards it to the PTV
Timetable API. The Android app then calls the Worker instead of PTV directly.

## Why

- The key is never embedded in the public APK (can't be extracted by users).
- Central place to **cache**, **rate-limit**, and **rotate** the key without an app update.
- All public traffic flows through one endpoint you control.

## Deploy (free tier)

1. Install Wrangler and sign in to Cloudflare:

   ```bash
   npm install -g wrangler
   wrangler login
   ```

2. From this `proxy/` folder, set your PTV secrets (you'll be prompted to paste each value):

   ```bash
   wrangler secret put PTV_DEV_ID    # your numeric PTV User ID, e.g. 30XXXXX
   wrangler secret put PTV_API_KEY   # your PTV API key (the signing secret)
   ```

3. Deploy:

   ```bash
   wrangler deploy
   ```

   Wrangler prints a URL like `https://ptvon-proxy.<your-subdomain>.workers.dev`.

4. Point the app at it — add this to the project root `local.properties` (gitignored) and rebuild:

   ```properties
   ptv.proxyUrl=https://ptvon-proxy.<your-subdomain>.workers.dev
   ```

   With `ptv.proxyUrl` set, the app ships **no** key and routes all PTV calls through the Worker.
   (Leave it blank to use direct mode with an embedded key.)

## Test

```bash
curl "https://ptvon-proxy.<your-subdomain>.workers.dev/v3/route_types"
```

Should return JSON with `"health":1`.

## Notes

- Add light caching/rate-limiting in `src/index.js` as needed (a 10s cache is already set).
- To rotate your key: `wrangler secret put PTV_API_KEY` again — no app update required.
