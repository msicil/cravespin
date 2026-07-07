# CraveRoll — Xcode signing setup

Follow these steps once per Mac (or when Xcode asks for a team).

## 1. Add your Apple ID to Xcode

1. Open **Xcode** (the CraveRoll project should already be open).
2. Menu: **Xcode → Settings…** (or **Preferences…** on older macOS).
3. Open the **Accounts** tab.
4. Click **+** (bottom left) → **Apple ID** → **Continue**.
5. Sign in with your Apple ID and complete 2FA if prompted.

You do **not** need a paid Apple Developer Program membership to run on the **Simulator**. A free Apple ID is enough.

To install on a **physical iPhone**, you need either:

- A free Apple ID (Personal Team, apps expire after ~7 days), or
- A paid [Apple Developer Program](https://developer.apple.com/programs/) membership ($99/year).

## 2. Enable signing on the CraveRoll target

1. In the left sidebar (Project Navigator), click the blue **CraveRoll** project icon.
2. Under **TARGETS**, select **CraveRoll**.
3. Open the **Signing & Capabilities** tab.
4. Check **Automatically manage signing**.
5. **Team**: choose your name (Personal Team) from the dropdown.
   - If the dropdown is empty, go back to step 1 and add your Apple ID.
6. **Bundle Identifier** should match your existing App Store app:
   - `com.cravespin.app` (default in this project)

Xcode will create a provisioning profile automatically for simulator and device testing.

## 3. Fix common errors

| Message | Fix |
|--------|-----|
| *Signing for "CraveRoll" requires a development team* | Select a **Team** in Signing & Capabilities. |
| *Failed to register bundle identifier* | Change **Bundle Identifier** to something unique (e.g. add your initials). |
| *Request widget family (systemMedium) is not supported* or *Failed to show Widget* | Toolbar scheme must be **CraveRoll**, not **CraveRollWidgetExtension**. The widget scheme only previews the home-screen widget; use **CraveRoll** to run the app on your phone. |
| *Communication with Apple failed* | Sign in again under **Xcode → Settings → Accounts**; check network. |
| *Untrusted Developer* on iPhone | On the phone: **Settings → General → VPN & Device Management** → trust your developer certificate. |

## 4. Run on Simulator (no device cable needed)

1. Toolbar: scheme **CraveRoll** (not CraveRollWidgetExtension), destination **iPhone 16** (or any simulator).
2. **Product → Run** (⌘R).

**Important:** If the scheme says **CraveRollWidgetExtension**, Xcode tries to show the home-screen widget instead of opening the app. Always pick **CraveRoll** for normal development.

## 5. Run on your iPhone (optional)

1. Connect and unlock the phone.
2. On the phone: trust the computer if prompted.
3. **Settings → Privacy & Security → Developer Mode** → On (iOS 16+).
4. Toolbar: scheme **CraveRoll** (not CraveRollWidgetExtension), destination: your iPhone.
5. **⌘R** — first build may ask to enable **Developer Mode** on the device (iOS 16+).

## 6. Google Places bundle ID (later)

When you create a Google Cloud API key, restrict it to this app’s **Bundle Identifier** (same string as in Signing & Capabilities, default `com.cravespin.app`).

CraveRoll sends that value as `X-Ios-Bundle-Identifier` on every Places request. If Google shows *“requests from this iOS app are blocked”*, add the **exact** bundle ID from Xcode to the key’s iOS app allowlist (or temporarily set Application restrictions to **None** while testing).
