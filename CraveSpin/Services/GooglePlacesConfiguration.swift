import Foundation

enum GooglePlacesConfiguration {
    private static let placeholder = "YOUR_GOOGLE_CLOUD_API_KEY"

    /// Google Places API key injected at build time via Config.xcconfig / Secrets.xcconfig → Info.plist.
    static var apiKey: String? {
        if let key = infoPlistKey, isUsable(key) { return key }
        if let key = legacyConfigPlistKey, isUsable(key) { return key }
        return nil
    }

    static var isConfigured: Bool { apiKey != nil }

    private static var infoPlistKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "GOOGLE_PLACES_API_KEY") as? String
    }

    /// Local dev fallback when Config.plist exists but xcconfig was not wired yet.
    private static var legacyConfigPlistKey: String? {
        guard
            let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
            let plist = NSDictionary(contentsOfFile: path),
            let key = plist["GOOGLE_PLACES_API_KEY"] as? String
        else {
            return nil
        }
        return key
    }

    private static func isUsable(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard trimmed != placeholder else { return false }
        // Unsubstituted Xcode build setting.
        guard !trimmed.hasPrefix("$(") else { return false }
        return true
    }
}
