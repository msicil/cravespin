import CoreLocation
import UIKit

/// Opens a restaurant in the Google Maps app (or Maps web) using name, address, coordinates, or place ID.
enum GoogleMapsLinker {
    static func open(restaurant: Restaurant) {
        if let googleMapsURL = restaurant.googleMapsURL {
            UIApplication.shared.open(googleMapsURL)
            return
        }

        let candidates = fallbackURLs(for: restaurant)
        guard !candidates.isEmpty else { return }

        for url in candidates {
            if url.scheme == "comgooglemaps" {
                guard UIApplication.shared.canOpenURL(url) else { continue }
                UIApplication.shared.open(url)
                return
            }
        }

        for url in candidates where url.scheme == "https" || url.scheme == "http" {
            UIApplication.shared.open(url)
            return
        }
    }

    static func normalizedPlaceID(_ raw: String?) -> String? {
        guard var id = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty else {
            return nil
        }
        if id.hasPrefix("places/") {
            id = String(id.dropFirst("places/".count))
        }
        return id
    }

    /// Search string that includes the restaurant name so Maps resolves the correct place.
    static func mapsSearchQuery(for restaurant: Restaurant) -> String {
        let name = restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let address = restaurant.address.trimmingCharacters(in: .whitespacesAndNewlines)

        if !name.isEmpty, !address.isEmpty {
            if address.localizedCaseInsensitiveContains(name) {
                return address
            }
            return "\(name), \(address)"
        }
        if !name.isEmpty { return name }
        return address
    }

    private static func hasUsableCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        guard CLLocationCoordinate2DIsValid(coordinate) else { return false }
        guard abs(coordinate.latitude) <= 90, abs(coordinate.longitude) <= 180 else { return false }
        if abs(coordinate.latitude) < 0.0001, abs(coordinate.longitude) < 0.0001 { return false }
        return true
    }

    private static func encodedQuery(_ text: String) -> String {
        text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
    }

    /// Built when Places API did not return `googleMapsUri` (e.g. demo data).
    private static func fallbackURLs(for restaurant: Restaurant) -> [URL] {
        var urls: [URL] = []
        let lat = restaurant.coordinate.latitude
        let lon = restaurant.coordinate.longitude
        let coordinateQuery = "\(lat),\(lon)"
        let hasCoordinate = hasUsableCoordinate(restaurant.coordinate)

        let searchQuery = mapsSearchQuery(for: restaurant)
        guard !searchQuery.isEmpty else { return urls }

        let encodedSearch = encodedQuery(searchQuery)
        let encodedName = encodedQuery(restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines))

        // Google Maps app: search by name (+ address) anchored to coordinates.
        if hasCoordinate {
            if let appSearch = URL(
                string: "comgooglemaps://?q=\(encodedSearch)&center=\(coordinateQuery)&zoom=17"
            ) {
                urls.append(appSearch)
            }
            if !restaurant.name.isEmpty, encodedName != encodedSearch,
               let appName = URL(
                   string: "comgooglemaps://?q=\(encodedName)&center=\(coordinateQuery)&zoom=17"
               ) {
                urls.append(appName)
            }
        } else if let appSearch = URL(string: "comgooglemaps://?q=\(encodedSearch)") {
            urls.append(appSearch)
        }

        if let placeID = normalizedPlaceID(restaurant.googlePlaceID),
           let web = URL(
               string: "https://www.google.com/maps/search/?api=1&query=\(encodedSearch)&query_place_id=\(placeID)"
           ) {
            // query includes name; place_id pins the exact listing when available.
            urls.append(web)
        }

        if let webSearch = URL(string: "https://www.google.com/maps/search/?api=1&query=\(encodedSearch)") {
            urls.append(webSearch)
        }

        if hasCoordinate,
           let mapsGoogle = URL(string: "https://maps.google.com/?q=\(encodedSearch)&center=\(coordinateQuery)&zoom=17") {
            urls.append(mapsGoogle)
        }

        // Last resort: coordinates only when name/address search URLs were already tried.
        if hasCoordinate {
            if let webCoord = URL(
                string: "https://www.google.com/maps/search/?api=1&query=\(coordinateQuery)"
            ) {
                urls.append(webCoord)
            }
        }

        return urls
    }
}
