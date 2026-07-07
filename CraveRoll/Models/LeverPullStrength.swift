import Foundation

/// How far the lever was pulled on release (25% increments).
enum LeverPullStrength: Int, Comparable, Sendable {
    case quarter = 1
    case half = 2
    case threeQuarter = 3
    case full = 4

    static func < (lhs: LeverPullStrength, rhs: LeverPullStrength) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Returns nil if the pull did not reach the 25% minimum.
    static func from(pullRatio: CGFloat) -> LeverPullStrength? {
        guard pullRatio >= 0.25 else { return nil }
        if pullRatio >= 1.0 { return .full }
        if pullRatio >= 0.75 { return .threeQuarter }
        if pullRatio >= 0.50 { return .half }
        return .quarter
    }

    var label: String {
        switch self {
        case .quarter: "25%"
        case .half: "50%"
        case .threeQuarter: "75%"
        case .full: "100%"
        }
    }

    /// Extra reel rotations and spin duration scale with pull strength.
    var spinProfile: SpinProfile {
        switch self {
        case .quarter:
            SpinProfile(loopRange: 3 ... 4, duration: 1.75, deceleration: 0.88)
        case .half:
            SpinProfile(loopRange: 5 ... 6, duration: 2.35, deceleration: 0.82)
        case .threeQuarter:
            SpinProfile(loopRange: 7 ... 8, duration: 3.0, deceleration: 0.76)
        case .full:
            SpinProfile(loopRange: 9 ... 11, duration: 3.85, deceleration: 0.68)
        }
    }
}

struct SpinProfile {
    let loopRange: ClosedRange<Int>
    let duration: TimeInterval
    /// Lower = harsher stop (more “forceful”).
    let deceleration: Double
}
