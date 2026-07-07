import CoreLocation
import Foundation

/// Nearby restaurant search via the Google Places API (New) Text Search endpoint.
/// Enable "Places API (New)" in Google Cloud Console and restrict the key to iOS bundle ID.
struct GooglePlacesService: PlacesServicing {
    private let apiKey: String
    private let session: URLSession

    /// Text Search returns up to 20 places per page; paginating up to 2 pages
    /// yields as many as 40 candidates so the reel feels like the full local list.
    private static let pageSize = 20
    private static let maxPages = 2

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    static func fromBundle() throws -> GooglePlacesService {
        guard let key = GooglePlacesConfiguration.apiKey else {
            throw PlacesServiceError.missingAPIKey
        }
        return GooglePlacesService(apiKey: key)
    }

    func fetchRestaurants(
        near coordinate: CLLocationCoordinate2D,
        filters: SpinFilters
    ) async throws -> [Restaurant] {
        var collected: [Restaurant] = []
        var seenIDs = Set<String>()
        var pageToken: String?

        for _ in 0 ..< Self.maxPages {
            let page = try await fetchPage(
                near: coordinate,
                filters: filters,
                pageToken: pageToken
            )

            let pageRestaurants = page.places?.map { place in
                Restaurant(
                    id: place.id,
                    name: place.displayName?.text ?? "Unknown",
                    address: place.formattedAddress ?? "",
                    coordinate: CLLocationCoordinate2D(
                        latitude: place.location?.latitude ?? coordinate.latitude,
                        longitude: place.location?.longitude ?? coordinate.longitude
                    ),
                    rating: place.rating,
                    priceLevel: place.priceLevel,
                    photoReferences: Array(place.photos?.compactMap(\.name).prefix(GooglePlacesPhotoService.slideshowPhotoCount) ?? []),
                    isOpenNow: place.currentOpeningHours?.openNow,
                    businessStatus: place.businessStatus,
                    googlePlaceID: GoogleMapsLinker.normalizedPlaceID(place.id),
                    googleMapsURL: place.googleMapsURL,
                    reservable: place.reservable,
                    websiteURL: place.websiteURL,
                    primaryType: place.primaryType,
                    types: place.types
                )
            } ?? []

            for restaurant in pageRestaurants where !seenIDs.contains(restaurant.id) {
                seenIDs.insert(restaurant.id)
                collected.append(restaurant)
            }

            guard let next = page.nextPageToken, !next.isEmpty else { break }
            pageToken = next
        }

        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let filtered = collected.filter { restaurant in
            // Text Search biases toward the circle but doesn't hard-restrict it,
            // so enforce the radius client-side to match the requested area.
            if filters.radiusMeters > 0 {
                let placeLocation = CLLocation(
                    latitude: restaurant.coordinate.latitude,
                    longitude: restaurant.coordinate.longitude
                )
                if origin.distance(from: placeLocation) > Double(filters.radiusMeters) {
                    return false
                }
            }
            if !filters.matchesOpenNow(
                isOpenNow: restaurant.isOpenNow,
                businessStatus: restaurant.businessStatus
            ) { return false }
            if filters.minRating > 0, (restaurant.rating ?? 0) < filters.minRating { return false }
            if !filters.matches(priceLevel: restaurant.priceLevel) { return false }
            return true
        }

        guard filtered.count >= 2 else {
            throw PlacesServiceError.apiError("Not enough restaurants found nearby. Try widening the radius or changing filters.")
        }

        return filtered
    }

    /// Fetches a single Text Search page. Pass the previous response's `nextPageToken`
    /// to advance; the request must otherwise stay identical across pages.
    private func fetchPage(
        near coordinate: CLLocationCoordinate2D,
        filters: SpinFilters,
        pageToken: String?
    ) async throws -> TextSearchResponse {
        var body: [String: Any] = [
            "textQuery": "restaurants",
            "includedType": "restaurant",
            "pageSize": Self.pageSize,
            "locationBias": [
                "circle": [
                    "center": [
                        "latitude": coordinate.latitude,
                        "longitude": coordinate.longitude,
                    ],
                    "radius": Double(filters.radiusMeters),
                ],
            ],
        ]
        if let pageToken {
            body["pageToken"] = pageToken
        }

        var request = URLRequest(url: URL(string: "https://places.googleapis.com/v1/places:searchText")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(
            "nextPageToken,places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.priceLevel,places.currentOpeningHours,places.businessStatus,places.photos,places.reservable,places.websiteUri,places.googleMapsUri,places.primaryType,places.types",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )
        // Required when the API key is restricted to iOS apps (bundle ID allowlist).
        if let bundleID = Bundle.main.bundleIdentifier {
            request.setValue(bundleID, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PlacesServiceError.invalidResponse
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let raw = Self.errorMessage(from: data) ?? "HTTP \(http.statusCode)"
            throw PlacesServiceError.apiError(Self.friendlyMessage(for: raw))
        }

        do {
            return try JSONDecoder().decode(TextSearchResponse.self, from: data)
        } catch {
            throw PlacesServiceError.decodeFailed(underlying: error)
        }
    }

    private static func friendlyMessage(for raw: String) -> String {
        let lower = raw.lowercased()
        guard lower.contains("ios") && lower.contains("blocked") else { return raw }
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        return """
        Google blocked this request for bundle ID “\(bundleID)”.
        In Google Cloud → APIs & Services → Credentials, edit your API key and add this exact bundle ID under iOS app restrictions (or set Application restrictions to None while testing).
        """
    }

    private static func errorMessage(from data: Data) -> String? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }
        return json["message"] as? String
    }
}

// MARK: - Places API (New) response shapes

private struct TextSearchResponse: Decodable {
    let places: [PlaceResult]?
    let nextPageToken: String?
}

private struct PlaceResult: Decodable {
    let id: String
    let displayName: DisplayName?
    let formattedAddress: String?
    let location: PlaceLocation?
    let rating: Double?
    let priceLevel: Int?
    let photos: [PlacePhoto]?
    let currentOpeningHours: OpeningHours?
    let businessStatus: String?
    let reservable: Bool?
    let websiteUri: String?
    let googleMapsUri: String?
    let primaryType: String?
    let types: [String]?

    var websiteURL: URL? {
        guard let websiteUri, !websiteUri.isEmpty else { return nil }
        return URL(string: websiteUri)
    }

    var googleMapsURL: URL? {
        guard let googleMapsUri, !googleMapsUri.isEmpty else { return nil }
        return URL(string: googleMapsUri)
    }

    enum CodingKeys: String, CodingKey {
        case id, displayName, formattedAddress, location, rating, priceLevel, photos
        case currentOpeningHours, businessStatus, reservable, websiteUri, googleMapsUri
        case primaryType, types
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decodeIfPresent(DisplayName.self, forKey: .displayName)
        formattedAddress = try container.decodeIfPresent(String.self, forKey: .formattedAddress)
        location = try container.decodeIfPresent(PlaceLocation.self, forKey: .location)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        photos = try container.decodeIfPresent([PlacePhoto].self, forKey: .photos)
        currentOpeningHours = try container.decodeIfPresent(OpeningHours.self, forKey: .currentOpeningHours)
        businessStatus = try container.decodeIfPresent(String.self, forKey: .businessStatus)
        reservable = try container.decodeIfPresent(Bool.self, forKey: .reservable)
        websiteUri = try container.decodeIfPresent(String.self, forKey: .websiteUri)
        googleMapsUri = try container.decodeIfPresent(String.self, forKey: .googleMapsUri)
        primaryType = try container.decodeIfPresent(String.self, forKey: .primaryType)
        types = try container.decodeIfPresent([String].self, forKey: .types)
        if let raw = try container.decodeIfPresent(String.self, forKey: .priceLevel) {
            priceLevel = Self.dollarLevel(from: raw)
        } else {
            priceLevel = nil
        }
    }

    /// Places API (New) returns enums like `PRICE_LEVEL_MODERATE`, not legacy 0–4 integers.
    private static func dollarLevel(from apiValue: String) -> Int? {
        switch apiValue {
        case "PRICE_LEVEL_FREE": return 0
        case "PRICE_LEVEL_INEXPENSIVE": return 1
        case "PRICE_LEVEL_MODERATE": return 2
        case "PRICE_LEVEL_EXPENSIVE": return 3
        case "PRICE_LEVEL_VERY_EXPENSIVE": return 4
        default: return nil
        }
    }
}

private struct DisplayName: Decodable {
    let text: String?
}

private struct PlaceLocation: Decodable {
    let latitude: Double?
    let longitude: Double?
}

private struct PlacePhoto: Decodable {
    let name: String?
}

private struct OpeningHours: Decodable {
    let openNow: Bool?
}
