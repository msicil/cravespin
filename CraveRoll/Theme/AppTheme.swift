import SwiftUI

enum AppTheme {
    // Dark navy shell (inspired by premium slot UI)
    static let navy = Color(red: 0.05, green: 0.07, blue: 0.12)
    static let navyElevated = Color(red: 0.09, green: 0.11, blue: 0.18)
    static let navyPanel = Color(red: 0.07, green: 0.09, blue: 0.15)

    // Metallic gold accents
    static let gold = Color(red: 0.92, green: 0.76, blue: 0.32)
    static let goldLight = Color(red: 1.0, green: 0.88, blue: 0.55)
    static let goldDark = Color(red: 0.72, green: 0.55, blue: 0.18)

    static let textPrimary = Color(red: 0.95, green: 0.90, blue: 0.75)
    static let textMuted = Color(red: 0.65, green: 0.62, blue: 0.58)
    static let closedRed = Color(red: 0.85, green: 0.35, blue: 0.32)

    static let wheelColors: [Color] = [gold, goldLight, Color(red: 0.85, green: 0.70, blue: 0.40), Color(red: 0.78, green: 0.62, blue: 0.28)]

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.05, blue: 0.10),
                navy,
                Color(red: 0.06, green: 0.08, blue: 0.14),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var goldGradient: LinearGradient {
        LinearGradient(colors: [goldLight, gold, goldDark], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var spinButtonGradient: LinearGradient {
        LinearGradient(colors: [goldLight, goldDark], startPoint: .top, endPoint: .bottom)
    }

    static var slotTitleGradient: LinearGradient {
        LinearGradient(colors: [goldLight, gold], startPoint: .top, endPoint: .bottom)
    }

    static var slotNeonGradient: LinearGradient {
        LinearGradient(colors: [goldLight, gold, goldDark], startPoint: .leading, endPoint: .trailing)
    }

    static var slotBackgroundGradient: LinearGradient {
        backgroundGradient
    }

    // Shared serif caps styling for CraveRoll, Winner, Restaurants, etc.
    static func brandTitleFont(size: CGFloat, weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static let brandTitleTracking: CGFloat = 1.2
    static let brandTitleCompactTracking: CGFloat = 0.8
}

// MARK: - Glass surfaces (dark + gold trim)

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background {
                glassBackground(cornerRadius: cornerRadius)
            }
    }

    @ViewBuilder
    private func glassBackground(cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            shape
                .fill(AppTheme.navyPanel.opacity(0.55))
                .glassEffect(.regular, in: shape)
                .overlay {
                    shape.strokeBorder(AppTheme.gold.opacity(0.28), lineWidth: 0.75)
                }
        } else {
            shape
                .fill(AppTheme.navyElevated.opacity(0.82))
                .overlay {
                    shape.fill(
                        LinearGradient(
                            colors: [AppTheme.gold.opacity(0.12), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
                .overlay {
                    shape.strokeBorder(AppTheme.gold.opacity(0.32), lineWidth: 0.75)
                }
        }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 18) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

struct GoldLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.gold.opacity(0.85))
            .textCase(.uppercase)
            .tracking(0.8)
    }
}

extension View {
    func goldLabel() -> some View {
        modifier(GoldLabel())
    }
}

struct RomanGoldButtonStyle: ButtonStyle {
    var isDimmed: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .serif).weight(.black))
            .tracking(1.1)
            .textCase(.uppercase)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.10, blue: 0.06), AppTheme.navy],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: AppTheme.goldLight.opacity(0.35), radius: 0, y: 1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                ZStack {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.goldDark,
                                    AppTheme.gold,
                                    AppTheme.goldLight.opacity(0.95),
                                    AppTheme.gold,
                                    AppTheme.goldDark.opacity(0.9),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.55), radius: 1, y: 3)
                        .shadow(color: AppTheme.gold.opacity(isDimmed ? 0.2 : 0.38), radius: isDimmed ? 6 : 8, y: 4)

                    Capsule(style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [AppTheme.goldLight.opacity(0.9), AppTheme.goldDark.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )

                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.28), lineWidth: 0.75)
                        .padding(2)
                        .blendMode(.overlay)
                }
            }
            .overlay {
                HStack {
                    Image(systemName: "laurel.leading")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.navy.opacity(0.35))
                        .padding(.leading, 14)
                    Spacer()
                    Image(systemName: "laurel.trailing")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.navy.opacity(0.35))
                        .padding(.trailing, 14)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .opacity(isDimmed ? 0.65 : 1)
    }
}

struct SlotSpinButtonStyle: ButtonStyle {
    var isSpinning: Bool

    func makeBody(configuration: Configuration) -> some View {
        RomanGoldButtonStyle(isDimmed: isSpinning).makeBody(configuration: configuration)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(AppTheme.navy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                Capsule(style: .continuous)
                    .fill(AppTheme.spinButtonGradient)
                    .opacity(isEnabled ? 1 : 0.45)
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(AppTheme.goldLight.opacity(0.5), lineWidth: 0.75)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct GhostGoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.gold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                Capsule(style: .continuous)
                    .strokeBorder(AppTheme.gold.opacity(0.45), lineWidth: 1)
                    .background(Capsule().fill(AppTheme.navyPanel.opacity(0.6)))
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
