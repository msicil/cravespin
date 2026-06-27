import SwiftUI

struct SplashView: View {
    private static let miniRowHeight: CGFloat = 38
    private static var nameCycleHeight: CGFloat { miniRowHeight * CGFloat(BrandLogoMark.cuisineNames.count) }
    private static let spinPeriod: TimeInterval = 1.35

    @State private var logoScale: CGFloat = 0.72
    @State private var logoOpacity: Double = 0
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            AppTheme.slotBackgroundGradient
                .ignoresSafeArea()

            GeometryReader { proxy in
                Path { path in
                    let spacing: CGFloat = 28
                    for x in stride(from: 0, through: proxy.size.width, by: spacing) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                    }
                    for y in stride(from: 0, through: proxy.size.height, by: spacing) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                    }
                }
                .stroke(AppTheme.gold.opacity(0.06), lineWidth: 0.5)
            }
            .ignoresSafeArea()

            VStack(spacing: 28) {
                TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                    BrandLogoMark(
                        reelWidth: 280,
                        rowHeight: Self.miniRowHeight,
                        scrollOffset: reelScrollOffset(at: timeline.date)
                    )
                    .opacity(logoOpacity)
                }

                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: "laurel.leading")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppTheme.gold.opacity(0.95))
                        Text("CraveSpin")
                            .font(AppTheme.brandTitleFont(size: 50))
                            .tracking(AppTheme.brandTitleTracking)
                            .textCase(.uppercase)
                            .foregroundStyle(AppTheme.slotTitleGradient)
                            .shadow(color: AppTheme.gold.opacity(glowPulse ? 0.58 : 0.28), radius: glowPulse ? 18 : 9)
                        Image(systemName: "laurel.trailing")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppTheme.gold.opacity(0.95))
                    }

                    Text("Spin · Dine · Discover")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.goldLight.opacity(0.9))
                        .tracking(1.2)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                logoScale = 1
                logoOpacity = 1
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    private func reelScrollOffset(at date: Date) -> CGFloat {
        let elapsed = date.timeIntervalSinceReferenceDate
        let progress = elapsed.truncatingRemainder(dividingBy: Self.spinPeriod) / Self.spinPeriod
        return -CGFloat(progress) * Self.nameCycleHeight
    }
}
