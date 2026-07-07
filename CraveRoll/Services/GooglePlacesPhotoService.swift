import Foundation
import UIKit

/// Loads restaurant photos from the Google Places API (New) media endpoint.
enum GooglePlacesPhotoService {
    static let slideshowPhotoCount = 8
    private static let cache = PhotoCache()

    static func image(for photoName: String, maxDimension: Int) async -> UIImage? {
        await cache.image(for: photoName, maxDimension: maxDimension)
    }
}

private actor PhotoCache {
    private var storage: [String: UIImage] = [:]

    func image(for photoName: String, maxDimension: Int) async -> UIImage? {
        let key = "\(photoName)|\(maxDimension)"
        if let cached = storage[key] {
            return cached
        }
        guard let image = await fetchPhoto(for: photoName, maxDimension: maxDimension) else {
            return nil
        }
        storage[key] = image
        return image
    }

    private func fetchPhoto(for photoName: String, maxDimension: Int) async -> UIImage? {
        guard let apiKey = apiKeyFromBundle() else { return nil }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "places.googleapis.com"
        components.path = "/v1/\(photoName)/media"
        components.queryItems = [
            URLQueryItem(name: "maxHeightPx", value: "\(maxDimension)"),
            URLQueryItem(name: "maxWidthPx", value: "\(maxDimension)"),
        ]

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        if let bundleID = Bundle.main.bundleIdentifier {
            request.setValue(bundleID, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                return nil
            }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    private func apiKeyFromBundle() -> String? {
        GooglePlacesConfiguration.apiKey
    }
}
