import SwiftUI

/// Flashing lights, glow, and shimmer layered on the reel while it spins.
struct ReelSpinEffects: View {
    let isSpinning: Bool
    var cornerRadius: CGFloat = 14

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let flash = (sin(time * 11) + 1) / 2
            let fastFlash = (sin(time * 18) + 1) / 2

            ZStack {
                if isSpinning {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            AppTheme.goldLight.opacity(0.25 + flash * 0.55),
                            lineWidth: 2.5 + flash * 2
                        )
                        .blur(radius: 1.5)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(AppTheme.gold.opacity(0.15 + fastFlash * 0.35), lineWidth: 4)

                    shimmerSweep(time: time)
                    marqueeBulbs(time: time)
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func shimmerSweep(time: Double) -> some View {
        GeometryReader { geo in
            let phase = time.truncatingRemainder(dividingBy: 0.9) / 0.9
            let x = -geo.size.width * 0.35 + phase * geo.size.width * 1.7

            LinearGradient(
                colors: [.clear, AppTheme.goldLight.opacity(0.45), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.28)
            .offset(x: x)
            .blendMode(.plusLighter)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private func marqueeBulbs(time: Double) -> some View {
        GeometryReader { geo in
            let bulbCount = 12
            let insetX: CGFloat = 7
            let activeIndex = Int((time * 14).rounded()) % bulbCount

            ForEach(0 ..< bulbCount, id: \.self) { index in
                let lit = activeIndex == (bulbCount - 1 - index)
                let y = geo.size.height * (CGFloat(index) + 0.5) / CGFloat(bulbCount)

                bulb(isLit: lit)
                    .position(x: insetX, y: y)

                bulb(isLit: lit)
                    .position(x: geo.size.width - insetX, y: y)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private func bulb(isLit: Bool) -> some View {
        Circle()
            .fill(isLit ? AppTheme.goldLight : AppTheme.gold.opacity(0.25))
            .frame(width: isLit ? 8 : 5, height: isLit ? 8 : 5)
            .shadow(color: AppTheme.gold.opacity(isLit ? 0.9 : 0), radius: isLit ? 7 : 0)
    }
}
