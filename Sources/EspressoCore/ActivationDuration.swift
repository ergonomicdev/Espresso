import Foundation

/// How long Espresso should keep the Mac awake once activated.
public enum ActivationDuration: Hashable, Sendable, CaseIterable, Identifiable {
    case indefinitely
    case minutes(Int)
    case hours(Int)

    public static let allCases: [ActivationDuration] = [
        .indefinitely,
        .minutes(5), .minutes(15), .minutes(30),
        .hours(1), .hours(2), .hours(5),
    ]

    public var id: String { storageKey }

    /// Length in seconds, or `nil` for indefinitely.
    public var interval: TimeInterval? {
        switch self {
        case .indefinitely: nil
        case .minutes(let m): TimeInterval(m * 60)
        case .hours(let h): TimeInterval(h * 3600)
        }
    }

    public var title: String {
        switch self {
        case .indefinitely: "Indefinitely"
        case .minutes(let m): m == 1 ? "1 Minute" : "\(m) Minutes"
        case .hours(let h): h == 1 ? "1 Hour" : "\(h) Hours"
        }
    }

    /// Stable string form for persisting in UserDefaults.
    public var storageKey: String {
        switch self {
        case .indefinitely: "indefinitely"
        case .minutes(let m): "\(m)m"
        case .hours(let h): "\(h)h"
        }
    }

    public init?(storageKey: String) {
        if storageKey == "indefinitely" {
            self = .indefinitely
            return
        }
        guard let unit = storageKey.last, let value = Int(storageKey.dropLast()), value > 0 else {
            return nil
        }
        switch unit {
        case "m": self = .minutes(value)
        case "h": self = .hours(value)
        default: return nil
        }
    }
}

public extension TimeInterval {
    /// Compact remaining-time string, e.g. "1:04:09" or "4:09".
    var espressoRemainingString: String {
        let total = max(0, Int(self.rounded(.up)))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}
