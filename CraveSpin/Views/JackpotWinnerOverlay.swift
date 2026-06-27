import SwiftUI

/// Full-screen jackpot overlay with celebration effects and winner details.
struct JackpotWinnerOverlay: View {
    let restaurant: Restaurant
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            JackpotCelebrationView(isActive: true)
                .ignoresSafeArea()

            WinnerPopupView(restaurant: restaurant, onDismiss: onDismiss)
                .padding(.horizontal, 20)
        }
    }
}
