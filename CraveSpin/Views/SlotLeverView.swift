import SwiftUI

/// Vertical slot lever — shorter centered groove; spin strength follows release position.
struct SlotLeverView: View {
    var isLocked: Bool
    var onPullRelease: (LeverPullStrength) -> Void

    /// Base groove height relative to reel viewport (2× base, then −15%).
    private static let baseSlotHeightRatio: CGFloat = 0.39
    private static let slotLengthMultiplier: CGFloat = 2 * 0.85
    private static let slotHorizontalBuffer: CGFloat = 9
    private static let slotVerticalBuffer: CGFloat = 10
    private static let pullClearanceBelow: CGFloat = 20

    private let armLength: CGFloat = 36
    private let armAngleFromUp: CGFloat = 52
    private let slotInset: CGFloat = 10

    static var knobClearanceAbove: CGFloat {
        36 * cos(52 * .pi / 180) + 14
    }

    static func slotGrooveHeight(forViewportHeight viewportHeight: CGFloat) -> CGFloat {
        viewportHeight * baseSlotHeightRatio * slotLengthMultiplier
    }

    /// Y position of the groove center inside the lever column (aligns with reel viewport center).
    static func slotCenterYInColumn(forViewportHeight viewportHeight: CGFloat) -> CGFloat {
        knobClearanceAbove + slotGrooveHeight(forViewportHeight: viewportHeight) / 2
    }

    /// Column tall enough for the groove, knob above, and pull travel below.
    static func columnHeight(forViewportHeight viewportHeight: CGFloat) -> CGFloat {
        slotGrooveHeight(forViewportHeight: viewportHeight) + knobClearanceAbove + pullClearanceBelow
    }

    @State private var pull: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let grooveHeight = Self.slotGrooveHeight(forViewportHeight: WheelLayout.viewportHeight)
            let slotCenterY = Self.slotCenterYInColumn(forViewportHeight: WheelLayout.viewportHeight)
            let layout = LeverLayout(
                size: geo.size,
                slotHeight: grooveHeight,
                slotCenterY: slotCenterY,
                slotInset: slotInset
            )
            let travel = isLocked ? 0 : min(pull, layout.maxPull)
            let base = CGPoint(
                x: layout.slotX,
                y: layout.slotTop + slotInset + travel
            )
            let tip = leverTip(from: base)

            ZStack {
                slotPanelChrome(layout: layout)

                slotGroove(
                    center: CGPoint(x: layout.slotX, y: layout.slotCenterY),
                    height: layout.slotHeight
                )

                slotEntry(at: base)

                leverArm(from: base, to: tip)
                    .opacity(isLocked ? 0.85 : 1)

                knobView
                    .position(tip)
                    .saturation(isLocked ? 0.7 : 1)
            }
            .gesture(dragGesture(maxPull: layout.maxPull))
        }
        .frame(width: 52)
        .contentShape(Rectangle())
        .allowsHitTesting(!isLocked)
        .accessibilityLabel("Slot lever")
        .accessibilityHint("Pull down at least twenty-five percent and release to spin")
    }

    private func leverTip(from base: CGPoint) -> CGPoint {
        let radians = armAngleFromUp * .pi / 180
        return CGPoint(
            x: base.x + armLength * sin(radians),
            y: base.y - armLength * cos(radians)
        )
    }

    private func slotPanelChrome(layout: LeverLayout) -> some View {
        let width = 12 + Self.slotHorizontalBuffer * 2
        let height = layout.slotHeight + Self.slotVerticalBuffer * 2

        return RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.13, green: 0.14, blue: 0.19),
                        Color(red: 0.07, green: 0.08, blue: 0.11),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [AppTheme.goldLight, AppTheme.gold, AppTheme.goldDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.75
                    )
            }
            .frame(width: width, height: height)
            .position(x: layout.slotX, y: layout.slotCenterY)
    }

    private func slotEntry(at point: CGPoint) -> some View {
        Circle()
            .fill(Color(red: 0.05, green: 0.06, blue: 0.09))
            .frame(width: 12, height: 12)
            .overlay {
                Circle()
                    .strokeBorder(Color.black.opacity(0.5), lineWidth: 0.75)
            }
            .position(point)
    }

    private func slotGroove(center: CGPoint, height: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.03, blue: 0.06),
                        Color(red: 0.06, green: 0.07, blue: 0.10),
                        Color(red: 0.02, green: 0.03, blue: 0.05),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 10, height: height)
            .overlay {
                Capsule()
                    .strokeBorder(Color.black.opacity(0.6), lineWidth: 0.75)
            }
            .position(center)
    }

    private func leverArm(from base: CGPoint, to tip: CGPoint) -> some View {
        ZStack {
            Path { path in
                path.move(to: base)
                path.addLine(to: tip)
            }
            .stroke(Color.black.opacity(0.4), style: StrokeStyle(lineWidth: 7, lineCap: .round))

            Path { path in
                path.move(to: base)
                path.addLine(to: tip)
            }
            .stroke(
                LinearGradient(
                    colors: [AppTheme.goldDark, AppTheme.goldLight, AppTheme.gold],
                    startPoint: .bottom,
                    endPoint: .top
                ),
                style: StrokeStyle(lineWidth: 5, lineCap: .round)
            )
        }
        .shadow(color: .black.opacity(0.3), radius: 1.5, x: 1, y: 1)
    }

    private var knobView: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [AppTheme.goldLight, AppTheme.gold, AppTheme.goldDark],
                    center: UnitPoint(x: 0.34, y: 0.30),
                    startRadius: 1,
                    endRadius: 14
                )
            )
            .frame(width: 26, height: 26)
            .overlay {
                Circle()
                    .strokeBorder(AppTheme.goldLight.opacity(0.8), lineWidth: 0.85)
            }
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(.white.opacity(0.55))
                    .frame(width: 7, height: 7)
                    .offset(x: 5, y: 5)
            }
            .shadow(color: .black.opacity(0.45), radius: 4, y: 2)
    }

    private func dragGesture(maxPull: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                pull = min(max(0, value.translation.height), maxPull)
            }
            .onEnded { _ in
                let releaseRatio = maxPull > 0 ? pull / maxPull : 0
                if let strength = LeverPullStrength.from(pullRatio: releaseRatio) {
                    onPullRelease(strength)
                }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
                    pull = 0
                }
            }
    }
}

private struct LeverLayout {
    let slotX: CGFloat
    let slotCenterY: CGFloat
    let slotHeight: CGFloat
    let slotTop: CGFloat
    let maxPull: CGFloat

    init(size: CGSize, slotHeight requestedHeight: CGFloat, slotCenterY requestedCenterY: CGFloat, slotInset: CGFloat) {
        slotX = size.width / 2
        slotHeight = min(requestedHeight, size.height - 16)
        slotCenterY = min(size.height - slotHeight / 2 - 4, max(slotHeight / 2 + 4, requestedCenterY))
        slotTop = slotCenterY - slotHeight / 2
        maxPull = max(24, slotHeight - slotInset * 2)
    }
}
