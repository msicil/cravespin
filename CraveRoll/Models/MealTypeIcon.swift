import Foundation

/// Maps Google place types (and name hints) to SF Symbols for the wheel reel.
enum MealTypeIcon {
    static func systemName(for restaurant: Restaurant) -> String {
        for type in placeTypeCandidates(from: restaurant) {
            if let icon = icon(forPlaceType: type) {
                return icon
            }
        }
        if let icon = iconFromName(restaurant.name) {
            return icon
        }
        return "fork.knife"
    }

    static func systemName(forName name: String) -> String {
        iconFromName(name) ?? "fork.knife"
    }

    private static func placeTypeCandidates(from restaurant: Restaurant) -> [String] {
        var candidates: [String] = []
        if let primaryType = restaurant.primaryType {
            candidates.append(primaryType)
        }
        if let types = restaurant.types {
            let ignored = Set(["restaurant", "food", "point_of_interest", "establishment", "meal_delivery", "meal_takeaway"])
            candidates.append(contentsOf: types.filter { !ignored.contains($0) })
        }
        return candidates
    }

    private static func icon(forPlaceType type: String) -> String? {
        switch type.lowercased() {
        case "sushi_restaurant", "japanese_restaurant", "ramen_restaurant":
            return "fish.fill"
        case "seafood_restaurant":
            return "fish.fill"
        case "pizza_restaurant":
            return "circle.grid.3x3.fill"
        case "mexican_restaurant", "taco_restaurant":
            return "flame.fill"
        case "chinese_restaurant", "asian_restaurant", "vietnamese_restaurant":
            return "takeoutbag.and.cup.and.straw.fill"
        case "thai_restaurant", "indian_restaurant", "korean_restaurant":
            return "flame.fill"
        case "italian_restaurant":
            return "wineglass.fill"
        case "french_restaurant", "fine_dining_restaurant":
            return "wineglass.fill"
        case "steak_house", "barbecue_restaurant", "bar_and_grill", "american_restaurant", "hawaiian_restaurant":
            return "flame.fill"
        case "hamburger_restaurant", "fast_food_restaurant", "sandwich_shop":
            return "takeoutbag.and.cup.and.straw.fill"
        case "cafe", "coffee_shop", "breakfast_restaurant", "brunch_restaurant", "diner":
            return "cup.and.saucer.fill"
        case "bakery", "dessert_shop", "ice_cream_shop", "donut_shop":
            return "birthday.cake.fill"
        case "vegan_restaurant", "vegetarian_restaurant":
            return "leaf.fill"
        case "mediterranean_restaurant", "greek_restaurant", "lebanese_restaurant", "middle_eastern_restaurant":
            return "leaf.fill"
        case "bar", "pub", "wine_bar", "brewery", "night_club":
            return "wineglass.fill"
        default:
            return nil
        }
    }

    private static func iconFromName(_ name: String) -> String? {
        let normalized = name.lowercased()
        let keywords: [(String, String)] = [
            ("taco", "flame.fill"),
            ("sushi", "fish.fill"),
            ("ramen", "fish.fill"),
            ("pizza", "circle.grid.3x3.fill"),
            ("grill", "flame.fill"),
            ("bbq", "flame.fill"),
            ("barbecue", "flame.fill"),
            ("steak", "flame.fill"),
            ("seafood", "fish.fill"),
            ("fish", "fish.fill"),
            ("cafe", "cup.and.saucer.fill"),
            ("coffee", "cup.and.saucer.fill"),
            ("bakery", "birthday.cake.fill"),
            ("diner", "cup.and.saucer.fill"),
            ("burger", "takeoutbag.and.cup.and.straw.fill"),
            ("thai", "flame.fill"),
            ("indian", "flame.fill"),
            ("saffron", "flame.fill"),
            ("wok", "flame.fill"),
            ("vegan", "leaf.fill"),
            ("veggie", "leaf.fill"),
            ("bistro", "wineglass.fill"),
            ("wine", "wineglass.fill"),
            ("brew", "wineglass.fill"),
            ("pan", "frying.pan.fill"),
            ("basil", "leaf.fill"),
            ("stone", "wineglass.fill"),
        ]

        for (keyword, icon) in keywords where normalized.contains(keyword) {
            return icon
        }
        return nil
    }
}
