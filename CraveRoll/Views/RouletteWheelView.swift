import SwiftUI

enum WheelLayout {
    static let rowHeight: CGFloat = 44
    static let visibleRows: CGFloat = 5
    static var viewportHeight: CGFloat { rowHeight * visibleRows }
    /// Greek header rule above the scrolling reel.
    static let reelHeaderHeight: CGFloat = 34

    /// Middle visible row index (0-based) — selection sits here.
    static var centerRowIndex: CGFloat { (visibleRows - 1) / 2 }

    static func reelCopies(restaurantCount: Int) -> Int {
        guard restaurantCount > 0 else { return 0 }
        // The longest pull travels ~13 full cycles; 16 copies covers that with a buffer.
        let copiesForTravel = 16
        // Small lists still need many copies so the reel reads as a "full" strip.
        let copiesForFullLook = Int(ceil(120.0 / Double(restaurantCount)))
        return max(copiesForTravel, copiesForFullLook)
    }
}

struct RouletteWheelView: View {
    let restaurants: [Restaurant]
    let colors: [Color]
    let scrollOffset: CGFloat
    let isSpinning: Bool
    let jackpotFlash: Bool
    var showsChrome: Bool = true

    private var reelItems: [ReelItem] {
        guard !restaurants.isEmpty else { return [] }
        let copies = WheelLayout.reelCopies(restaurantCount: restaurants.count)
        return (0 ..< restaurants.count * copies).map { offset in
            let index = offset % restaurants.count
            let restaurant = restaurants[index]
            return ReelItem(
                id: "reel-\(offset)-\(restaurant.id)",
                name: restaurant.name,
                mealIcon: restaurant.mealIconSystemName,
                accent: colors[index],
                stripeIndex: index
            )
        }
    }

    var body: some View {
        let stack = VStack(spacing: 0) {
            GreekHeaderRule()
                .frame(height: WheelLayout.reelHeaderHeight)
            reelBody
        }
        .padding(WheelChrome.contentInset)

        if showsChrome {
            stack
                .background {
                    // Owns its own TimelineView so the glow pulse doesn't force the
                    // (potentially hundreds of rows) reel to rebuild 20x/second.
                    WheelGlowBackground(isSpinning: isSpinning, jackpotFlash: jackpotFlash)
                }
                .clipShape(RoundedRectangle(cornerRadius: WheelChrome.cornerRadius, style: .continuous))
                .overlay {
                    GreekReelFrame(
                        cornerRadius: WheelChrome.cornerRadius,
                        isHighlighted: isSpinning || jackpotFlash
                    )
                }
                .overlay {
                    ReelSpinEffects(isSpinning: isSpinning, cornerRadius: WheelChrome.cornerRadius)
                }
                .shadow(
                    color: AppTheme.gold.opacity(isSpinning ? 0.34 : jackpotFlash ? 0.4 : 0.1),
                    radius: isSpinning ? 14 : jackpotFlash ? 16 : 6,
                    y: 2
                )
                .scaleEffect(jackpotFlash ? 1.012 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: jackpotFlash)
                .animation(.easeInOut(duration: 0.3), value: isSpinning)
        } else {
            stack
        }
    }

    private var reelBody: some View {
        ZStack {
            reelPanel

            if isSpinning {
                vignetteOverlay
            }

            rowDividers

            GreekSelectionFrame(isJackpot: jackpotFlash, isSpinning: isSpinning && !jackpotFlash)
                .frame(height: WheelLayout.rowHeight - 2)
                .padding(.horizontal, 3)
        }
        .frame(height: WheelLayout.viewportHeight)
    }

    private var vignetteOverlay: some View {
        LinearGradient(
            colors: [
                AppTheme.gold.opacity(0.12),
                .clear,
                .clear,
                AppTheme.gold.opacity(0.12),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }

    private var reelPanel: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                ForEach(reelItems) { item in
                    WheelRow(item: item, isSpinning: isSpinning)
                }
            }
            .frame(width: proxy.size.width, alignment: .top)
            .offset(y: WheelLayout.centerRowIndex * WheelLayout.rowHeight - scrollOffset)
        }
        .clipped()
    }

    private var rowDividers: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< Int(WheelLayout.visibleRows) - 1, id: \.self) { _ in
                Spacer()
                    .frame(height: WheelLayout.rowHeight)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.gold.opacity(isSpinning ? 0.12 : 0.05),
                                AppTheme.gold.opacity(isSpinning ? 0.55 : 0.35),
                                AppTheme.gold.opacity(isSpinning ? 0.12 : 0.05),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }
            Spacer()
                .frame(height: WheelLayout.rowHeight)
        }
        .allowsHitTesting(false)
    }
}

/// Isolated so the frame-rate glow pulse only rebuilds two rounded rectangles,
/// instead of the entire scrolling reel, on every animation tick.
private struct WheelGlowBackground: View {
    let isSpinning: Bool
    let jackpotFlash: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: isSpinning ? 1 / 20 : 1)) { timeline in
            let pulse = isSpinning
                ? (sin(timeline.date.timeIntervalSinceReferenceDate * 8) + 1) / 2
                : 0

            ZStack {
                RoundedRectangle(cornerRadius: WheelChrome.cornerRadius, style: .continuous)
                    .fill(WheelChrome.fillGradient)

                if isSpinning || jackpotFlash {
                    RoundedRectangle(cornerRadius: WheelChrome.cornerRadius, style: .continuous)
                        .fill(AppTheme.gold.opacity(0.04 + pulse * 0.08))
                }
            }
        }
    }
}

private struct ReelItem: Identifiable {
    let id: String
    let name: String
    let mealIcon: String
    let accent: Color
    let stripeIndex: Int
}

private struct WheelRow: View {
    let item: ReelItem
    var isSpinning: Bool = false

    private var displayName: String {
        let trimmed = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Unnamed restaurant" : trimmed
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.mealIcon)
                .font(.caption.weight(.bold))
                .foregroundStyle(item.accent)
                .shadow(color: isSpinning ? item.accent.opacity(0.5) : .clear, radius: 4)
                .frame(width: 18, alignment: .center)

            Text(displayName)
                .font(.system(.subheadline, design: .serif).weight(.semibold))
                .foregroundStyle(isSpinning ? AppTheme.textPrimary : AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .frame(height: WheelLayout.rowHeight)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(
                    item.stripeIndex.isMultiple(of: 2)
                        ? Color(red: 0.12, green: 0.14, blue: 0.20).opacity(isSpinning ? 1 : 0.9)
                        : Color(red: 0.09, green: 0.11, blue: 0.17).opacity(isSpinning ? 1 : 0.85)
                )
        }
    }
}
