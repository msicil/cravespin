import SwiftUI

/// Fireworks, confetti, and gold burst effects for the winner overlay.
struct JackpotCelebrationView: View {
    var isActive: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                guard isActive else { return }

                let glowRect = CGRect(origin: .zero, size: size)
                context.fill(
                    Path(ellipseIn: glowRect.insetBy(dx: -size.width * 0.1, dy: -size.height * 0.1)),
                    with: .radialGradient(
                        Gradient(colors: [
                            AppTheme.gold.opacity(0.22),
                            AppTheme.gold.opacity(0.04),
                            .clear,
                        ]),
                        center: CGPoint(x: size.width * 0.5, y: size.height * 0.42),
                        startRadius: 20,
                        endRadius: max(size.width, size.height) * 0.6
                    )
                )

                for burst in 0 ..< 6 {
                    drawFirework(in: &context, size: size, seed: burst, time: t)
                }

                for piece in 0 ..< 28 {
                    drawConfetti(in: &context, size: size, index: piece, time: t)
                }
            }
        }
        .allowsHitTesting(false)
        .drawingGroup()
    }

    private func drawFirework(
        in context: inout GraphicsContext,
        size: CGSize,
        seed: Int,
        time: Double
    ) {
        let cycle = 1.4 + Double(seed % 3) * 0.35
        let phase = time.truncatingRemainder(dividingBy: cycle) / cycle
        guard phase < 1 else { return }

        let progress = min(1, phase * 1.35)
        let fade = max(0, 1 - progress)
        let radius = 30 + progress * 120

        let anchors: [CGPoint] = [
            CGPoint(x: 0.22, y: 0.28),
            CGPoint(x: 0.78, y: 0.24),
            CGPoint(x: 0.5, y: 0.18),
            CGPoint(x: 0.15, y: 0.42),
            CGPoint(x: 0.85, y: 0.38),
            CGPoint(x: 0.5, y: 0.32),
        ]
        let origin = anchors[seed % anchors.count]
        let center = CGPoint(x: origin.x * size.width, y: origin.y * size.height)

        for ray in 0 ..< 12 {
            let angle = Double(ray) / 12 * .pi * 2 + Double(seed)
            let end = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )

            var path = Path()
            path.move(to: center)
            path.addLine(to: end)
            context.stroke(
                path,
                with: .color(AppTheme.goldLight.opacity(0.75 * fade)),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
            )

            let dotRect = CGRect(x: end.x - 3, y: end.y - 3, width: 6, height: 6)
            context.fill(
                Path(ellipseIn: dotRect),
                with: .color((seed.isMultiple(of: 2) ? AppTheme.gold : AppTheme.goldLight).opacity(fade))
            )
        }
    }

    private func drawConfetti(
        in context: inout GraphicsContext,
        size: CGSize,
        index: Int,
        time: Double
    ) {
        let xSeed = Double((index * 37) % 100) / 100
        let speed = 0.35 + Double(index % 5) * 0.08
        let phase = (time * speed + xSeed).truncatingRemainder(dividingBy: 1)

        let x = xSeed * size.width
        let y = -40 + phase * (size.height + 80)
        let width: CGFloat = index.isMultiple(of: 2) ? 8 : 5
        let height: CGFloat = index.isMultiple(of: 2) ? 5 : 9

        var transform = CGAffineTransform(translationX: x, y: y)
        transform = transform.rotated(by: (phase * 360 + Double(index * 29)) * .pi / 180)
        transform = transform.translatedBy(x: -width / 2, y: -height / 2)

        var piece = Path(roundedRect: CGRect(x: 0, y: 0, width: width, height: height), cornerRadius: 2)
        piece = piece.applying(transform)

        context.fill(
            piece,
            with: .color((index.isMultiple(of: 3) ? AppTheme.gold : AppTheme.goldLight).opacity(0.85))
        )
    }
}
