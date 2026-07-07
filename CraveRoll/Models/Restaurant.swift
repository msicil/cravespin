import Foundation
import CoreLocation

struct Restaurant: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let rating: Double?
    let priceLevel: Int?
    /// Google Places photo resource names, e.g. `places/.../photos/...`.
    let photoReferences: [String]
    let isOpenNow: Bool?
    /// Google `businessStatus`, e.g. OPERATIONAL, CLOSED_TEMPORARILY.
    let businessStatus: String?
    let googlePlaceID: String?
    /// From Places API `googleMapsUri` — opens this place in Google Maps.
    let googleMapsURL: URL?
    /// From Google Places `reservable` — place supports reservations (book on their site).
    let reservable: Bool?
    let websiteURL: URL?
    /// Google `primaryType`, e.g. `italian_restaurant`.
    let primaryType: String?
    /// Google place `types` array.
    let types: [String]?

    var mealIconSystemName: String {
        MealTypeIcon.systemName(for: self)
    }

    /// Show Reserve when Google says reservable and we have a website to open.
    var canReserve: Bool {
        reservable == true && websiteURL != nil
    }

    var canOpenInMaps: Bool {
        googleMapsURL != nil
            || GoogleMapsLinker.normalizedPlaceID(googlePlaceID) != nil
            || !GoogleMapsLinker.mapsSearchQuery(for: self).isEmpty
            || (coordinate.latitude != 0 || coordinate.longitude != 0)
    }

    var priceLabel: String? {
        guard let priceLevel, priceLevel > 0 else { return nil }
        return String(repeating: "$", count: min(priceLevel, 4))
    }

    var hasPhotos: Bool {
        !photoReferences.isEmpty
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension CLLocationCoordinate2D: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}
