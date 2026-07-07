import UIKit

@MainActor
enum SlotHaptics {
    private static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    // Long-lived generators: firing a cold generator adds latency and can hitch
    // the first spin, so keep them alive and pre-warmed with prepare().
    private static let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let notification = UINotificationFeedbackGenerator()

    /// Warm the Taptic Engine ahead of the first spin (call on appear).
    static func prepare() {
        guard !isSimulator else { return }
        heavyImpact.prepare()
        lightImpact.prepare()
        notification.prepare()
    }

    static func spinStart() {
        guard !isSimulator else { return }
        heavyImpact.impactOccurred()
        // Keep it warm for the settle notification / next spin.
        heavyImpact.prepare()
    }

    static func reelTick() {
        guard !isSimulator else { return }
        lightImpact.impactOccurred(intensity: 0.5)
        lightImpact.prepare()
    }

    static func jackpot() {
        guard !isSimulator else { return }
        notification.notificationOccurred(.success)
    }
}
