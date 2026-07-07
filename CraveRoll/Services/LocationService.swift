import CoreLocation
import MapKit

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var gpsCoordinate: CLLocationCoordinate2D?
    @Published private(set) var currentCityName: String = "Current location"
    @Published private(set) var selectedLocation: SearchLocation
    @Published private(set) var searchCoordinate: CLLocationCoordinate2D?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isResolvingCity = false
    @Published private(set) var citySearchResults: [SearchLocation] = []
    @Published private(set) var isSearchingCities = false
    @Published private(set) var isInitialLocationReady = false
    @Published var citySearchQuery = ""

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var geocodeTask: Task<Void, Never>?
    private var citySearchTask: Task<Void, Never>?
    private var hasAppliedInitialGPS = false

    override init() {
        let placeholder = SearchLocation.presets[0]
        authorizationStatus = manager.authorizationStatus
        selectedLocation = .current(title: "Current location", coordinate: placeholder.coordinate)
        searchCoordinate = placeholder.coordinate
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        refreshInitialLocationReadiness()
    }

    func requestAccess() {
        manager.requestWhenInUseAuthorization()
    }

    func refreshLocation() {
        errorMessage = nil
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        manager.requestLocation()
    }

    func select(_ location: SearchLocation) {
        selectedLocation = location
        if location.isCurrentLocation {
            searchCoordinate = gpsCoordinate ?? location.coordinate
            if gpsCoordinate == nil {
                refreshLocation()
            }
        } else {
            searchCoordinate = location.coordinate
        }
    }

    func searchCities(matching query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        citySearchTask?.cancel()

        guard trimmed.count >= 2 else {
            citySearchResults = []
            isSearchingCities = false
            return
        }

        citySearchTask = Task {
            isSearchingCities = true
            defer { isSearchingCities = false }

            try? await Task.sleep(for: .milliseconds(280))
            if Task.isCancelled { return }

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = trimmed
            request.resultTypes = .address

            do {
                let response = try await MKLocalSearch(request: request).start()
                if Task.isCancelled { return }

                var seen = Set<String>()
                citySearchResults = response.mapItems.compactMap { item in
                    SearchLocation.from(mapItem: item)
                }
                .filter { location in
                    let key = "\(location.title.lowercased())-\(location.coordinate.latitude)-\(location.coordinate.longitude)"
                    guard !seen.contains(key) else { return false }
                    seen.insert(key)
                    return true
                }
                .prefix(12)
                .map { $0 }
            } catch {
                if Task.isCancelled { return }
                citySearchResults = []
            }
        }
    }

    private func applyGPSUpdate(_ coordinate: CLLocationCoordinate2D) {
        gpsCoordinate = coordinate
        if !hasAppliedInitialGPS {
            hasAppliedInitialGPS = true
            select(.current(title: currentCityName, coordinate: coordinate))
        } else if selectedLocation.isCurrentLocation {
            searchCoordinate = coordinate
            selectedLocation = .current(title: currentCityName, coordinate: coordinate)
        }
        refreshInitialLocationReadiness()
        resolveCityName(for: coordinate)
    }

    private func refreshInitialLocationReadiness() {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isInitialLocationReady = hasAppliedInitialGPS
        case .denied, .restricted:
            isInitialLocationReady = true
        case .notDetermined:
            isInitialLocationReady = false
        @unknown default:
            isInitialLocationReady = true
        }
    }

    private func resolveCityName(for coordinate: CLLocationCoordinate2D) {
        geocodeTask?.cancel()
        geocodeTask = Task {
            isResolvingCity = true
            defer { isResolvingCity = false }

            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if Task.isCancelled { return }
                let name = Self.cityName(from: placemarks.first) ?? "Current location"
                currentCityName = name
                if selectedLocation.isCurrentLocation {
                    selectedLocation = .current(title: name, coordinate: coordinate)
                }
            } catch {
                if Task.isCancelled { return }
                currentCityName = "Current location"
            }
        }
    }

    private static func cityName(from placemark: CLPlacemark?) -> String? {
        guard let placemark else { return nil }
        if let city = placemark.locality, !city.isEmpty { return city }
        if let sublocality = placemark.subAdministrativeArea, !sublocality.isEmpty { return sublocality }
        if let area = placemark.administrativeArea, !area.isEmpty { return area }
        if let name = placemark.name, !name.isEmpty { return name }
        return nil
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            } else if authorizationStatus == .denied || authorizationStatus == .restricted {
                if selectedLocation.isCurrentLocation {
                    let fallback = SearchLocation.presets[0]
                    select(fallback)
                }
            }
            refreshInitialLocationReadiness()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            applyGPSUpdate(location.coordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
        }
    }
}
