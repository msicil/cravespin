import SwiftUI

/// Restaurant reel with pull lever on the right.
struct SlotMachineView: View {
    let restaurants: [Restaurant]
    let colors: [Color]
    let scrollOffset: CGFloat
    let isSpinning: Bool
    let jackpotFlash: Bool
    let onSpin: (LeverPullStrength) -> Void

    private var leverColumnHeight: CGFloat {
        SlotLeverView.columnHeight(forViewportHeight: WheelLayout.viewportHeight)
    }

    private var leverTopPadding: CGFloat {
        let reelCenterY = WheelLayout.reelHeaderHeight + WheelLayout.viewportHeight / 2
        let slotCenterInColumn = SlotLeverView.slotCenterYInColumn(forViewportHeight: WheelLayout.viewportHeight)
        return reelCenterY - slotCenterInColumn
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RouletteWheelView(
                restaurants: restaurants,
                colors: colors,
                scrollOffset: scrollOffset,
                isSpinning: isSpinning,
                jackpotFlash: jackpotFlash
            )
            .frame(maxWidth: .infinity)
            .padding(.trailing, 40)

            SlotLeverView(isLocked: isSpinning, onPullRelease: onSpin)
                .frame(width: 52, height: leverColumnHeight, alignment: .center)
                .padding(.top, max(0, leverTopPadding))
                .padding(.trailing, -8)
        }
        .padding(.leading, 2)
        .padding(.trailing, 12)
        .padding(.bottom, 4)
    }
}
