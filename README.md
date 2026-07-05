# CraveSpin

CraveSpin is an iPhone app that spins a roulette wheel to pick a restaurant near you. It pulls restaurant details from **Google Places (New)**. The winner card opens **Google Maps**, and **Reserve** opens the restaurant’s website when Google marks the place as reservable.

## Open in Xcode

1. Open `CraveSpin.xcodeproj` in Xcode (double-click or **File → Open**).
2. Select the **CraveSpin** scheme and an iPhone simulator.
3. Press **Run** (⌘R).

Copy secrets when you are ready for live restaurant data:

```bash
cp Secrets.xcconfig.example Secrets.xcconfig
```

Open `Secrets.xcconfig`, paste your Google Places API key, then **Archive** for App Store. The key is injected at build time (not stored in git).

Until `Secrets.xcconfig` has a valid key, Debug builds use **mock restaurants**. Release archives **fail the build** if the key is missing.

## Google Places setup

1. Create a project in [Google Cloud Console](https://console.cloud.google.com/).
2. Enable **Places API (New)**.
3. Create an API key restricted to your iOS bundle ID (`com.cravespin.app`) and **Places API (New)**.
   - The bundle ID must match **Signing & Capabilities** in Xcode exactly.
   - If you changed the bundle ID locally, add that string in Google Cloud too.
   - CraveSpin sends `X-Ios-Bundle-Identifier` on each request (required for iOS-restricted keys).
4. Add the key to `Secrets.xcconfig` as `GOOGLE_PLACES_API_KEY` (see `Secrets.xcconfig.example`).

If you see *“requests from this iOS app are blocked”*, the key’s iOS allowlist does not include your app’s current bundle ID.

## Reservations

CraveSpin reads Google Places **`reservable`** and **`websiteUri`**. When a place is reservable and has a website, the winner card shows **Reserve** (opens the restaurant site) plus **Maps**. Otherwise you get a full-width **Maps** button only.

`reservable` and `websiteUri` are included in the Nearby Search field mask — they may increase Places API billing tier; see [Place data fields](https://developers.google.com/maps/documentation/places/web-service/data-fields).

## Project path

`/Users/michaelsiciliano/Projects/CraveSpin`
