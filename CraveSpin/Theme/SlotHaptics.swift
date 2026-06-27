import UIKit

enum SlotHaptics {
    private static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    static func spinStart() {
        guard !isSimulator else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func reelTick() {
        guard !isSimulator else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
    }

    static func jackpot() {
        guard !isSimulator else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
