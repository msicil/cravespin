import CoreLocation

struct MockPlacesService: PlacesServicing {
    func fetchRestaurants(
        near coordinate: CLLocationCoordinate2D,
        filters: SpinFilters
    ) async throws -> [Restaurant] {
        try await Task.sleep(for: .milliseconds(400))

        let samples: [Restaurant] = [
            Restaurant(
                id: "1",
                name: "Harbor Grill",
                address: "120 Pier Ave",
                coordinate: offset(coordinate, lat: 0.004, lon: 0.002),
                rating: 4.6,
                priceLevel: 2,
                photoReferences: [],
                isOpenNow: true,
                businessStatus: "OPERATIONAL",
                googlePlaceID: "ChIJmock1",
                googleMapsURL: nil,
                reservable: true,
                websiteURL: URL(string: "https://example.com/harbor-grill"),
                primaryType: "steak_house",
                types: ["steak_house", "restaurant", "food"]
            ),
            Restaurant(
                id: "2",
                name: "Basil & Stone",
                address: "88 Oak Street",
                coordinate: offset(coordinate, lat: -0.003, lon: 0.005),
                rating: 4.4,
                priceLevel: 3,
                photoReferences: [],
                isOpenNow: true,
                businessStatus: "OPERATIONAL",
                googlePlaceID: "ChIJmock2",
                googleMapsURL: nil,
                reservable: false,
                websiteURL: URL(string: "https://example.com/basil-stone"),
                primaryType: "italian_restaurant",
                types: ["italian_restaurant", "restaurant", "food"]
            ),
            Restaurant(
                id: "3",
                name: "Night Owl Tacos",
                address: "14 Market Lane",
                coordinate: offset(coordinate, lat: 0.001, lon: -0.004),
                rating: 4.8,
                priceLevel: 1,
                photoReferences: [],
                isOpenNow: filters.openNowOnly ? true : false,
                businessStatus: "OPERATIONAL",
                googlePlaceID: "ChIJmock3",
                googleMapsURL: nil,
                reservable: nil,
                websiteURL: nil,
                primaryType: "mexican_restaurant",
                types: ["mexican_restaurant", "restaurant", "food"]
            ),
            Restaurant(
                id: "4",
                name: "Copper Pan",
                address: "501 Main Road",
                coordinate: offset(coordinate, lat: -0.005, lon: -0.002),
                rating: 4.2,
                priceLevel: 2,
                photoReferences: [],
                isOpenNow: true,
                businessStatus: "OPERATIONAL",
                googlePlaceID: "ChIJmock4",
                googleMapsURL: nil,
                reservable: true,
                websiteURL: URL(string: "https://example.com/copper-pan"),
                primaryType: "brunch_restaurant",
                types: ["brunch_restaurant", "restaurant", "food"]
            ),
            Restaurant(
                id: "5",
                name: "Saffron Table",
                address: "9 Plaza Drive",
                coordinate: offset(coordinate, lat: 0.006, lon: -0.001),
                rating: 4.5,
                priceLevel: 3,
                photoReferences: [],
                isOpenNow: true,
                businessStatus: "OPERATIONAL",
                googlePlaceID: "ChIJmock5",
                googleMapsURL: nil,
                reservable: false,
                websiteURL: nil,
                primaryType: "indian_restaurant",
                types: ["indian_restaurant", "restaurant", "food"]
            ),
        ]

        return samples.filter { restaurant in
            if !filters.matchesOpenNow(
                isOpenNow: restaurant.isOpenNow,
                businessStatus: restaurant.businessStatus
            ) { return false }
            if filters.minRating > 0, (restaurant.rating ?? 0) < filters.minRating { return false }
            if !filters.matches(priceLevel: restaurant.priceLevel) { return false }
            return true
        }
    }

    private func offset(
        _ coordinate: CLLocationCoordinate2D,
        lat: Double,
        lon: Double
    ) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: coordinate.latitude + lat,
            longitude: coordinate.longitude + lon
        )
    }
}
