# Publishing PTVon to TestFlight

This is the one-time setup to get PTVon onto TestFlight so anyone with the link
can install it. The app itself is already keyless (it talks to the Cloudflare
proxy), so testers never need a PTV DevID or API key.

> **What only you can do:** the steps below require *your* Apple ID and a paid
> Apple Developer Program membership. Apple ties signing certificates and the
> app record to your account, and I can't enter your Apple credentials or pay
> the membership fee on your behalf. Once you've done the account steps and
> handed me (or the script) the Team ID + API key, the build & upload is a
> single command.

## 1. Prerequisites (account, ~one time)

1. **Enroll in the Apple Developer Program** — https://developer.apple.com/programs/
   ($99 USD / year). Required for TestFlight; the free tier can't upload builds.
2. **Create the app record** in App Store Connect:
   - https://appstoreconnect.apple.com → **Apps** → **+** → **New App**
   - Platform: iOS · Name: `PTVon` · Bundle ID: `com.ptvon.app`
     (if the bundle ID isn't listed, the archive step below auto-creates it via
     `-allowProvisioningUpdates`, or add it under Certificates, IDs & Profiles)
   - SKU: anything unique, e.g. `ptvon-ios`.
3. **Create an App Store Connect API key** (lets the CLI upload without a password):
   - App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API**
   - **+** to generate a key with the **App Manager** role.
   - Download the `AuthKey_XXXXXX.p8` **once** (Apple only lets you download it a
     single time) and note the **Key ID** and **Issuer ID** shown on that page.
   - Move the file somewhere stable, e.g. `~/private_keys/AuthKey_XXXXXX.p8`.

## 2. Build & upload (repeatable, one command)

From the `ios/` folder:

```bash
TEAM_ID=YOUR_TEAM_ID \
ASC_KEY_ID=YOUR_KEY_ID \
ASC_ISSUER_ID=YOUR_ISSUER_ID \
ASC_KEY_PATH=~/private_keys/AuthKey_XXXXXX.p8 \
./scripts/build-testflight.sh
```

(Your **Team ID** is the 10-character code at
https://developer.apple.com/account → Membership details.)

The script archives a signed Release build, exports it, and uploads it straight
to TestFlight. The build appears in App Store Connect → your app → **TestFlight**
after Apple finishes processing (≈5–15 min).

### Prefer clicking? Use Xcode instead of the script

1. Open `PTVon.xcodeproj`, select the **PTVon** scheme, set the run destination
   to **Any iOS Device**.
2. In **Signing & Capabilities**, pick your Team (turn on *Automatically manage
   signing* for both the app and the widget extension targets).
3. **Product → Archive**, then in the Organizer choose
   **Distribute App → App Store Connect → Upload**.

## 3. Invite testers

In App Store Connect → your app → **TestFlight**:

- **Internal testing**: add up to 100 people on your team — instant, no review.
- **External testing / public link**: create a group, add the build, submit for
  a quick Beta App Review, then enable the **Public Link** so anyone can install
  via the TestFlight app. Up to 10,000 external testers.

## Notes

- **Export compliance** is pre-answered: the app sets
  `ITSAppUsesNonExemptEncryption = NO` (it only uses standard HTTPS), so you
  won't be prompted on every build. If App Store Connect still asks, answer
  "No" to the encryption question once.
- **Two bundle IDs** ship in this app: `com.ptvon.app` (the app) and
  `com.ptvon.app.widgets` (the Live Activity / Dynamic Island widget extension).
  Automatic signing creates/registers both for you.
- **Siri** ("Hey Siri, next departure in PTVon") only runs on a **signed** build
  — i.e. exactly the TestFlight build this produces. It does not run on the
  unsigned simulator build because iOS won't execute background App Intents for a
  bundle with no Team ID.
