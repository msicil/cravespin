import SwiftUI

enum WheelChrome {
    static let cornerRadius: CGFloat = 14

    static let contentInset: CGFloat = 3

    static var fillGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.12, blue: 0.20),
                AppTheme.navy,
                Color(red: 0.05, green: 0.07, blue: 0.12),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct WheelClusterChrome: View {
    var isHighlighted: Bool
    var pulse: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: WheelChrome.cornerRadius, style: .continuous)
                .fill(WheelChrome.fillGradient)

            if isHighlighted {
                RoundedRectangle(cornerRadius: WheelChrome.cornerRadius, style: .continuous)
                    .fill(AppTheme.gold.opacity(0.04 + pulse * 0.08))
            }
        }
        .overlay {
            GreekReelFrame(cornerRadius: WheelChrome.cornerRadius, isHighlighted: isHighlighted)
        }
    }
}

struct GreekReelFrame: View {
    var cornerRadius: CGFloat = 14
    var isHighlighted: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: isHighlighted ? 1 / 24 : 1)) { timeline in
            let pulse = isHighlighted
                ? (sin(timeline.date.timeIntervalSinceReferenceDate * 10) + 1) / 2
                : 0

            ZStack {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: cornerRadius + 2, style: .continuous)
                        .strokeBorder(AppTheme.goldLight.opacity(0.2 + pulse * 0.45), lineWidth: 5)
                        .blur(radius: 4)
                }

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [AppTheme.goldLight, AppTheme.gold, AppTheme.goldDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHighlighted ? 2.0 + pulse * 1.8 : 1.75
                    )
            }
        }
        .allowsHitTesting(false)
    }
}

struct GreekHeaderRule: View {
    var title: String = "Restaurants"
    var showsDisclosure: Bool = false
    var isExpanded: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            ruleSegment
            Image(systemName: "laurel.leading")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.gold.opacity(0.7))
            Text(title)
                .font(AppTheme.brandTitleFont(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.goldLight)
                .tracking(AppTheme.brandTitleCompactTracking)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Image(systemName: "laurel.trailing")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.gold.opacity(0.7))
            ruleSegment
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .padding(.trailing, showsDisclosure ? 28 : 0)
        .background {
            LinearGradient(
                colors: [AppTheme.navyElevated, AppTheme.navyPanel],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.gold.opacity(0.5), AppTheme.gold.opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .overlay(alignment: .trailing) {
            if showsDisclosure {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.gold.opacity(0.9))
                    .padding(.trailing, 14)
            }
        }
    }

    private var ruleSegment: some View {
        Rectangle()
            .fill(AppTheme.gold.opacity(0.35))
            .frame(height: 0.75)
            .frame(maxWidth: .infinity)
    }
}

struct GreekSelectionFrame: View {
    var isJackpot: Bool
    var isSpinning: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: (isJackpot || isSpinning) ? 1 / 24 : 1)) { timeline in
            let pulse = (isJackpot || isSpinning)
                ? (sin(timeline.date.timeIntervalSinceReferenceDate * (isJackpot ? 8 : 14)) + 1) / 2
                : 0

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        AppTheme.gold.opacity(
                            isJackpot ? 0.18 + pulse * 0.12
                                : isSpinning ? 0.08 + pulse * 0.16
                                : 0.07
                        )
                    )

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [AppTheme.goldLight, AppTheme.gold, AppTheme.goldLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: isJackpot ? 2.75 + pulse * 0.5 : isSpinning ? 2.0 + pulse * 1.2 : 2.25
                    )
            }
            .shadow(
                color: AppTheme.gold.opacity(isJackpot ? 0.5 : isSpinning ? 0.25 + pulse * 0.35 : 0.2),
                radius: isJackpot ? 12 : isSpinning ? 8 + pulse * 6 : 6
            )
        }
    }
}
