# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

PTVon — live Victorian (Melbourne) public-transport departures. **One git repo, three sub-projects that ship the same product on different platforms:**

| Path | Platform | Stack |
|------|----------|-------|
| `app/` | Android | Kotlin · Jetpack Compose / Material 3 · MVVM + Hilt · Retrofit/OkHttp · DataStore |
| `ios/` | iOS + watchOS | SwiftUI · ActivityKit · WidgetKit · WatchConnectivity · generated with XcodeGen |
| `proxy/` | Cloudflare Worker | JS — holds the PTV credentials and signs requests so the apps ship keyless |

The Android app is the original; the iOS app is a feature-parity port plus iOS-only surfaces (Live Activity / Dynamic Island, Home/StandBy widgets, Apple Watch app + complication).

## The keyless architecture (read this first)

The PTV Timetable API v3 requires every request to carry a `devid` and an **HMAC-SHA1 `signature` computed over the request path + query** (not the host), with `devid` appended before signing. PTVon never ships that key in a public build. Instead:

- **`proxy/` is a Cloudflare Worker** that stores the PTV `devid`/`apiKey` as Worker secrets, signs each incoming `/v3/...` request, and forwards it to PTV. It also fronts the same `/v3/...` paths the apps already use, so the apps just swap the base URL.
- **iOS** is always keyless: `PtvService.baseURL` points at the deployed Worker. No PTV secret exists anywhere in `ios/`.
- **Android** can run three ways, chosen at build time from `local.properties`: direct with `ptv.devId`/`ptv.apiKey` (signed locally by `PtvAuthInterceptor`), via the proxy with `ptv.proxyUrl`, or — with all blank — **demo mode** on bundled sample boards. Weather (Open-Meteo) is always live and keyless on both platforms.

Endpoints used across both apps: `/v3/departures/...`, `/v3/search/{term}`, `/v3/disruptions/stop/{id}`, `/v3/pattern/run/{ref}/route_type/{rt}` (for "alight at" arrival tracking).

## Building & running

### Android (`app/`)
Toolchain is **not on PATH** — set it explicitly:
```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"   # JDK 21
./gradlew :app:assembleDebug          # build APK
./gradlew :app:installDebug           # build + install to connected device
# adb lives at ~/Library/Android/sdk/platform-tools/adb
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell monkey -p com.ptvon -c android.intent.category.LAUNCHER 1   # launch
```
Gradle wrapper 8.11.1 · AGP 8.7.3 · Kotlin 2.0.21 · compileSdk 34 · minSdk 26 · `applicationId com.ptvon`. `java.time` works on minSdk 26 via core-library desugaring. Secrets/SDK path live in `local.properties` (gitignored) — see `README.md`.

### iOS / watchOS (`ios/`)
The `.xcodeproj` is **generated** — never hand-edit it. Edit `ios/project.yml` and regenerate. After adding/removing any source file you must regenerate.
```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer   # full Xcode, not CLT
export PATH="/opt/homebrew/bin:$PATH"                              # xcodegen (brew)
cd ios && xcodegen generate

# Simulator build (no signing):
xcodebuild -project PTVon.xcodeproj -scheme PTVon \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build

# Device build (signed): pass your team, let Xcode manage provisioning:
xcodebuild -project PTVon.xcodeproj -scheme PTVon -configuration Debug \
  -destination "platform=iOS,id=<DEVICE_UDID>" \
  DEVELOPMENT_TEAM=<TEAM_ID> -allowProvisioningUpdates build
xcrun devicectl device install app --device <UDID> <DerivedData>/.../PTVon.app
```
Targets: `PTVon` (app) → embeds `PTVonWidgetsExtension` (Live Activity + Home/StandBy widgets) and `PTVonWatch` (watchOS app) → embeds `PTVonWatchWidgets` (complication). Deployment floor **iOS 17** (Live Activity `ActivityContent` API needs ≥16.2; Liquid Glass `.glassEffect` is iOS 26, gated with `#available`). TestFlight steps + scripts are in `ios/TESTFLIGHT.md`.

### Proxy (`proxy/`)
```bash
cd proxy && npx wrangler dev          # local
npx wrangler deploy                   # deploy
npx wrangler secret put PTV_DEV_ID    # set credentials (also PTV_API_KEY)
```

## High-level structure

### Android (`app/src/main/java/com/ptvon/`)
Clean-ish MVVM with UDF. `data/remote/` holds Retrofit `PtvApi` + DTOs; `PtvAuthInterceptor` signs (or the proxy does); `ServerTimeInterceptor`/`TimeSource` make countdowns rely on server time, not the device clock. `domain/DepartureMapper` turns DTOs into UI-ready `Departure`s (prefers `estimated` over `scheduled`). `data/local/StopPreferencesRepository` persists pinned stops (DataStore). `ui/dashboard/` is the main screen (`DashboardViewModel` + `StationDepartureCard`). Live tracking is **two cooperating pieces** in `core/notifications/`: `TrackingService` (a foreground service showing the ongoing lock-screen countdown) and `AlertScheduler` (AlarmManager **exact** alarms at fixed lead minutes → `DepartureAlarmReceiver`); WorkManager isn't precise enough for to-the-minute transit alerts.

### iOS (`ios/`)
`Shared/` = code compiled into **both** the app and the widget extension (`DepartureAttributes` for the Live Activity, `RouteType`, `Color+Hex`). `PTVon/` is the app: `PtvService` (actor → proxy), `StopStore` (selected stops), `LiveActivityController` (starts/advances the Live Activity), `BackgroundScheduler` (BGTask + local notifications for the auto-window feature), weather (`WeatherProvider`/`WeatherBackground` — the animated, condition-driven backdrop), `Theme.swift` (adaptive day/night colours). `PTVonWidgets/` is the Live Activity + Home/StandBy widgets. `WatchApp/` + `WatchWidgets/` are the watch app + complication; the watch's stop list is mirrored from the phone over **WatchConnectivity** (`WatchSync` on phone ⇄ `WatchStops` on watch) — there is no App Group, so the watch widget falls back to the city stop.

## Non-obvious gotchas

- **iOS shared code boundary:** the watch targets and the iOS widget target list *individual* source files in `project.yml` (Models, PtvService, KnownStops, RouteType, Color+Hex). Do **not** add `Shared/DepartureAttributes.swift` to a watch target — it imports ActivityKit, which is iOS-only and won't compile for watchOS.
- **iOS Siri App Intents** register but only *execute* on a **signed** build (device/TestFlight). On an unsigned simulator build `linkd` rejects them ("no teamId") — this is expected, not a code bug.
- **Installing to a physical Apple Watch** is finicky: the watch needs its own Developer Mode on, must be **unlocked and on the same Wi-Fi as the Mac**, and Xcode must have "discovered" its architecture (force it with `xcrun devicectl device info details --device <watchUDID>` before building). `ios/scripts/install-watch.sh` automates the retry loop.
- **Never publish an APK built with `ptv.devId`/`ptv.apiKey` filled in** — that embeds the key. Public builds must be keyless (proxy). `local.properties` is gitignored and must stay out of commits.
- **Express detection is best-effort** — the PTV feed's `flags` field rarely marks express, so the "Express" highlight only appears when PTV actually flags it.
- Commit/push only when asked; `ios/` is currently untracked.
