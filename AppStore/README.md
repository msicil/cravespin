# App Store assets

## Routing coverage file — do NOT upload

`CraveRollRoutingCoverage.geojson` is **not** required for CraveRoll.

CraveRoll does **not** provide in-app turn-by-turn directions. It opens **Google Maps** for navigation. Uploading the GeoJSON on App Store Connect without declaring the app as a routing app causes:

**ITMS-90118: Invalid routing app setting**

### If you see that error

1. App Store Connect → **CraveRoll** → **App Information**
2. Remove the **Routing App Coverage File** (delete / clear it)
3. Bump the **Build** number in Xcode and upload a new archive

Do **not** enable Maps routing capabilities in Xcode unless you implement full `MKDirections` routing in the app.
