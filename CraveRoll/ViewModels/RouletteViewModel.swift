import CoreLocation
import SwiftUI

@MainActor
final class RouletteViewModel: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    @Published var selectedRestaurant: Restaurant?
    @Published var filters = SpinFilters()
    @Published var isLoading = false
    @Published var isSpinning = false
    @Published var jackpotFlash = false
    @Published var showWinnerPopup = false
    @Published var errorMessage: String?
    @Published var wheelScrollOffset: CGFloat = 0
    @Published var useLivePlaces = false

    private let mockPlaces: PlacesServicing
    private var livePlaces: PlacesServicing?
    private var spinTask: Task<Void, Never>?

    init(mockPlaces: PlacesServicing = MockPlacesService()) {
        self.mockPlaces = mockPlaces
    }

    func configureLivePlacesIfAvailable() {
        do {
            livePlaces = try GooglePlacesService.fromBundle()
            useLivePlaces = true
        } catch {
            livePlaces = nil
            useLivePlaces = false
        }
    }

    var activePlacesService: PlacesServicing {
        if useLivePlaces, let livePlaces { return livePlaces }
        return mockPlaces
    }

    func loadRestaurants(near coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetched = try await activePlacesService.fetchRestaurants(
                near: coordinate,
                filters: filters
            )
            let results = Self.dedupedByNearestLocation(fetched, near: coordinate)
            restaurants = results
            selectedRestaurant = nil
            jackpotFlash = false
            showWinnerPopup = false
            let defaultIndex = min(2, max(0, results.count - 1))
            wheelScrollOffset = results.isEmpty ? 0 : centeredScrollOffset(for: defaultIndex)
            if results.isEmpty {
                errorMessage = "No restaurants matched your filters. Try widening the radius."
            }
        } catch {
            errorMessage = error.localizedDescription
            restaurants = []
            wheelScrollOffset = 0
        }
    }

    func spin(pullStrength: LeverPullStrength = .half) {
        guard restaurants.count >= 2, !isSpinning else { return }

        spinTask?.cancel()
        SlotSounds.cancel()

        let index = Int.random(in: 0 ..< restaurants.count)
        let profile = pullStrength.spinProfile
        let loops = Int.random(in: profile.loopRange)
        let spinDuration = profile.duration
        let cycle = cycleHeight
        let start = wheelScrollOffset
        let end = centeredScrollOffset(for: index)
        var travel = CGFloat(loops) * cycle + (end - start)
        let minTravel = cycle * CGFloat(max(2, pullStrength.rawValue))
        if travel < minTravel { travel += cycle }

        isSpinning = true
        jackpotFlash = false
        showWinnerPopup = false
        SlotHaptics.spinStart()
        SlotSounds.beginSpin(duration: spinDuration)

        let decel = profile.deceleration
        withAnimation(.timingCurve(0.02, decel, 0.06, 1.0, duration: spinDuration)) {
            wheelScrollOffset = start + travel
        }

        spinTask = Task { @MainActor in
            defer { isSpinning = false }

            let tickCount = max(4, pullStrength.rawValue * 2)
            let tickInterval = spinDuration / Double(tickCount)

            for tick in 0 ..< tickCount {
                if Task.isCancelled {
                    SlotSounds.cancel()
                    return
                }
                try? await Task.sleep(for: .seconds(tickInterval))
                if Task.isCancelled {
                    SlotSounds.cancel()
                    return
                }
                if tick < tickCount - 1 {
                    SlotHaptics.reelTick()
                }
            }

            if Task.isCancelled {
                SlotSounds.cancel()
                return
            }

            selectedRestaurant = restaurants[index]
            settleWheel(on: index)
            jackpotFlash = true
            SlotSounds.finishWithWinner()
            SlotHaptics.jackpot()

            try? await Task.sleep(for: .milliseconds(280))
            if Task.isCancelled { return }

            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                showWinnerPopup = true
                jackpotFlash = false
            }
        }
    }

    func dismissWinner() {
        withAnimation(.easeOut(duration: 0.25)) {
            showWinnerPopup = false
            jackpotFlash = false
        }
    }

    private func settleWheel(on index: Int) {
        guard !restaurants.isEmpty else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            wheelScrollOffset = centeredScrollOffset(for: index)
        }
    }

    /// Offset so the winner is centered and five rows stay filled (uses a higher reel copy when needed).
    private func centeredScrollOffset(for index: Int) -> CGFloat {
        let rowHeight = WheelLayout.rowHeight
        let center = Int(WheelLayout.centerRowIndex)
        let count = restaurants.count
        let reelIndex = index >= center ? index : index + count
        return CGFloat(reelIndex) * rowHeight
    }

    private var cycleHeight: CGFloat {
        CGFloat(restaurants.count) * WheelLayout.rowHeight
    }

    func segmentColors(count: Int) -> [Color] {
        (0 ..< count).map { AppTheme.wheelColors[$0 % AppTheme.wheelColors.count] }
    }

    private static func normalizedName(_ restaurant: Restaurant) -> String {
        restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Collapses multiple locations of the same restaurant (same name) down to
    /// only the one closest to the search location, so duplicate names can never
    /// appear on the wheel together. Original ordering of the surviving picks is
    /// preserved.
    static func dedupedByNearestLocation(
        _ restaurants: [Restaurant],
        near coordinate: CLLocationCoordinate2D
    ) -> [Restaurant] {
        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var nearestByName: [String: (restaurant: Restaurant, distance: CLLocationDistance)] = [:]
        var order: [String] = []

        for restaurant in restaurants {
            let key = normalizedName(restaurant)
            let distance = origin.distance(
                from: CLLocation(
                    latitude: restaurant.coordinate.latitude,
                    longitude: restaurant.coordinate.longitude
                )
            )
            if let existing = nearestByName[key] {
                if distance < existing.distance {
                    nearestByName[key] = (restaurant, distance)
                }
            } else {
                nearestByName[key] = (restaurant, distance)
                order.append(key)
            }
        }

        return order.compactMap { nearestByName[$0]?.restaurant }
    }
}
