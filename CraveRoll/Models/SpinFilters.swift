import Foundation

struct SpinFilters: Equatable {
    /// Default search radius: 5 miles.
    var radiusMeters: Int = SpinFilters.milesToMeters(5)
    var minRating: Double = 4.0
    /// Selected Google price levels 1–4 ($ … $$$$). Empty or all selected = any price.
    var selectedPriceLevels: Set<Int> = Set(Self.priceLevels)
    var openNowOnly: Bool = true

    static let maxMinRating: Double = 4.5
    static let priceLevels = [1, 2, 3, 4]

    /// 1, 2, 5, 10, and 15 mile options.
    static let radiusOptions: [Int] = [1, 2, 5, 10, 15].map { milesToMeters($0) }

    static func milesToMeters(_ miles: Int) -> Int {
        Int((Double(miles) * 1_609.34).rounded())
    }

    var radiusLabel: String {
        let miles = Double(radiusMeters) / 1_609.34
        if miles >= 10 {
            return String(format: "%.0f mi", miles)
        }
        if miles >= 1 {
            return abs(miles - miles.rounded()) < 0.15
                ? String(format: "%.0f mi", miles.rounded())
                : String(format: "%.1f mi", miles)
        }
        return String(format: "%.1f mi", miles)
    }

    /// No price filtering when nothing or everything is selected.
    var isAnyPrice: Bool {
        let allLevels = Set(Self.priceLevels)
        return selectedPriceLevels.isEmpty || selectedPriceLevels == allLevels
    }

    var appliesPriceFilter: Bool {
        !isAnyPrice
    }

    var priceSelectionLabel: String? {
        guard appliesPriceFilter else { return nil }
        return selectedPriceLevels.sorted().map { Self.priceLevelLabel($0) }.joined(separator: ", ")
    }

    static func priceLevelLabel(_ level: Int) -> String {
        String(repeating: "$", count: min(level, 4))
    }

    func matches(priceLevel: Int?) -> Bool {
        guard !isAnyPrice else { return true }
        guard let priceLevel else { return true }
        return selectedPriceLevels.contains(priceLevel)
    }

    /// Nearby Search (New) has no server-side open-now flag; filter on returned hours/status.
    func matchesOpenNow(isOpenNow: Bool?, businessStatus: String?) -> Bool {
        guard openNowOnly else { return true }
        if let businessStatus, businessStatus != "OPERATIONAL" {
            return false
        }
        return isOpenNow == true
    }
}
