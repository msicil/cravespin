import Foundation

extension Notification.Name {
    static let widgetSpinRequested = Notification.Name("widgetSpinRequested")
}

/// Deep link from the home-screen widget: open the app and spin once ready.
enum WidgetSpinRequest {
    static let spinURL = URL(string: "cravespin://spin")!

    static var isPending = false

    static func handle(url: URL) {
        guard url.scheme == "cravespin", url.host == "spin" else { return }
        isPending = true
        NotificationCenter.default.post(name: .widgetSpinRequested, object: nil)
    }

    static func clear() {
        isPending = false
    }
}
