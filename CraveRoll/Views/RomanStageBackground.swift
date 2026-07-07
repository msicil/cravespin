import SwiftUI

/// One laurel pair arranged as a semicircle opening toward the wheel.
struct StageLaurelArch: View {
    enum Placement {
        case top
        case bottom
    }

    let placement: Placement

    private let laurelSize: CGFloat = 112
    private let archTilt: Double = 56

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            laurelHalf(name: "laurel.leading", isLeading: true)
            Spacer(minLength: 0)
            laurelHalf(name: "laurel.trailing", isLeading: false)
        }
        .scaleEffect(y: placement == .bottom ? -1 : 1)
        .frame(height: 92)
        .padding(.horizontal, 10)
        .allowsHitTesting(false)
    }

    private func laurelHalf(name: String, isLeading: Bool) -> some View {
        Image(systemName: name)
            .font(.system(size: laurelSize, weight: .regular))
            .foregroundStyle(laurelGradient)
            .shadow(color: AppTheme.gold.opacity(0.32), radius: 6, y: 2)
            .rotationEffect(.degrees(isLeading ? archTilt : -archTilt))
            .offset(y: placement == .top ? 10 : 0)
    }

    private var laurelGradient: LinearGradient {
        LinearGradient(
            colors: [AppTheme.goldLight, AppTheme.gold, AppTheme.goldDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Golden temple columns framing the full screen stage.
struct RomanStageBackground: View {
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                TempleColumn()
                    .frame(width: min(64, geo.size.width * 0.15))
                Spacer(minLength: 0)
                TempleColumn(mirrored: true)
                    .frame(width: min(64, geo.size.width * 0.15))
            }
            .padding(.horizontal, 0)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
    }
}

private struct TempleColumn: View {
    var mirrored: Bool = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let capitalHeight = min(34, geo.size.height * 0.065)
            let baseHeight = min(22, geo.size.height * 0.042)
            let plinthHeight = min(10, geo.size.height * 0.02)
            let shaftTop = capitalHeight + 2
            let shaftBottom = geo.size.height - baseHeight - plinthHeight - 2
            let shaftHeight = max(0, shaftBottom - shaftTop)
            let shaftWidth = width * 0.76

            ZStack(alignment: .top) {
                columnCapital(width: width, height: capitalHeight)

                columnShaft(width: shaftWidth, height: shaftHeight)
                    .offset(y: shaftTop)

                columnBase(width: width * 0.88, torusHeight: baseHeight * 0.45)
                    .offset(y: shaftBottom)

                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.goldDark.opacity(0.5), AppTheme.gold.opacity(0.35)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: width * 0.92, height: plinthHeight)
                    .offset(y: geo.size.height - plinthHeight)
            }
            .scaleEffect(x: mirrored ? -1 : 1, y: 1, anchor: .center)
        }
    }

    private func columnCapital(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.goldLight.opacity(0.7), AppTheme.gold, AppTheme.goldDark.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width * 0.96, height: height * 0.28)
                .shadow(color: .black.opacity(0.25), radius: 1, y: 1)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.goldLight.opacity(0.55), AppTheme.gold.opacity(0.8), AppTheme.goldDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: width * 0.82, height: height * 0.52)
                .offset(y: height * 0.22)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(AppTheme.goldDark.opacity(0.45))
                        .frame(height: 1)
                }

            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(AppTheme.goldDark.opacity(0.35))
                .frame(width: width * 0.7, height: height * 0.12)
                .offset(y: height * 0.82)
        }
        .frame(width: width, height: height)
    }

    private func columnShaft(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.goldDark.opacity(0.38),
                            AppTheme.gold.opacity(0.22),
                            AppTheme.goldDark.opacity(0.42),
                            AppTheme.gold.opacity(0.18),
                            AppTheme.goldDark.opacity(0.36),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            HStack(spacing: width * 0.09) {
                ForEach(0 ..< 7, id: \.self) { index in
                    Capsule()
                        .fill(
                            index.isMultiple(of: 2)
                                ? AppTheme.goldDark.opacity(0.28)
                                : AppTheme.goldLight.opacity(0.12)
                        )
                        .frame(width: max(1, width * 0.045), height: height * 0.94)
                }
            }

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [AppTheme.goldLight.opacity(0.25), .clear, AppTheme.goldDark.opacity(0.35)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 0.75
                )
        }
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 0)
    }

    private func columnBase(width: CGFloat, torusHeight: CGFloat) -> some View {
        VStack(spacing: 1) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.gold.opacity(0.55), AppTheme.goldDark.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: torusHeight)

            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(AppTheme.goldDark.opacity(0.5))
                .frame(height: torusHeight * 0.55)
        }
        .frame(width: width)
    }
}
