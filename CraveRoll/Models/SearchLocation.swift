import CoreLocation
import MapKit

struct SearchLocation: Identifiable, Equatable {
    static let currentLocationID = "current"

    let id: String
    let title: String
    let coordinate: CLLocationCoordinate2D

    var isCurrentLocation: Bool { id == Self.currentLocationID }

    static func current(title: String, coordinate: CLLocationCoordinate2D) -> SearchLocation {
        SearchLocation(id: currentLocationID, title: title, coordinate: coordinate)
    }

    static func from(mapItem: MKMapItem) -> SearchLocation? {
        let placemark = mapItem.placemark
        guard let coordinate = placemark.location?.coordinate else { return nil }
        let title = placemark.locality
            ?? placemark.name
            ?? mapItem.name
            ?? "Unknown"
        let id = "search-\(title)-\(coordinate.latitude)-\(coordinate.longitude)"
        return SearchLocation(id: id, title: title, coordinate: coordinate)
    }

    static let presets: [SearchLocation] = [
        SearchLocation(id: "sf", title: "San Francisco", coordinate: .init(latitude: 37.7749, longitude: -122.4194)),
        SearchLocation(id: "nyc", title: "New York", coordinate: .init(latitude: 40.7128, longitude: -74.0060)),
        SearchLocation(id: "la", title: "Los Angeles", coordinate: .init(latitude: 34.0522, longitude: -118.2437)),
        SearchLocation(id: "chi", title: "Chicago", coordinate: .init(latitude: 41.8781, longitude: -87.6298)),
        SearchLocation(id: "aus", title: "Austin", coordinate: .init(latitude: 30.2672, longitude: -97.7431)),
        SearchLocation(id: "sea", title: "Seattle", coordinate: .init(latitude: 47.6062, longitude: -122.3321)),
        SearchLocation(id: "mia", title: "Miami", coordinate: .init(latitude: 25.7617, longitude: -80.1918)),
        SearchLocation(id: "den", title: "Denver", coordinate: .init(latitude: 39.7392, longitude: -104.9903)),
    ]
}
