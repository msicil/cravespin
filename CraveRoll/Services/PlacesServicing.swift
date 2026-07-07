import CoreLocation

protocol PlacesServicing: Sendable {
    func fetchRestaurants(
        near coordinate: CLLocationCoordinate2D,
        filters: SpinFilters
    ) async throws -> [Restaurant]
}

enum PlacesServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(String)
    case decodeFailed(underlying: Error)
    case network(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add your Google Places API key in Secrets.xcconfig (copy from Secrets.xcconfig.example), then rebuild."
        case .invalidResponse:
            return "Could not read restaurant data from Google Places."
        case .apiError(let message):
            return message
        case .decodeFailed:
            return "Google Places returned an unexpected response format. Try updating the app."
        case .network(let underlying):
            return underlying.localizedDescription
        }
    }
}
