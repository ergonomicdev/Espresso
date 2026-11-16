import Combine
import Foundation

/// Owns the keep-awake state: whether Espresso is active and, if timed, when it ends.
@MainActor
public final class AwakeController: ObservableObject {
    @Published public private(set) var isActive = false
    /// When a timed activation ends; `nil` while inactive or active indefinitely.
    @Published public private(set) var endDate: Date?

    private let assertion: SleepAssertion
    private let now: () -> Date
    private var expiryTimer: Timer?

    public init(assertion: SleepAssertion = PowerSleepAssertion(), now: @escaping () -> Date = Date.init) {
        self.assertion = assertion
        self.now = now
    }

    public var remaining: TimeInterval? {
        endDate.map { max(0, $0.timeIntervalSince(now())) }
    }

    /// Activates (or re-activates with a new duration). Returns `false` if the
    /// power assertion could not be created.
    @discardableResult
    public func activate(for duration: ActivationDuration) -> Bool {
        guard assertion.acquire() else {
            deactivate()
            return false
        }
        isActive = true
        endDate = duration.interval.map { now().addingTimeInterval($0) }
        scheduleExpiry()
        return true
    }

    public func deactivate() {
        expiryTimer?.invalidate()
        expiryTimer = nil
        assertion.release()
        isActive = false
        endDate = nil
    }

    public func toggle(defaultDuration: ActivationDuration) {
        if isActive {
            deactivate()
        } else {
            activate(for: defaultDuration)
        }
    }

    /// Deactivates if a timed activation has run out.
    public func checkExpiration() {
        if let endDate, now() >= endDate {
            deactivate()
        }
    }

    private func scheduleExpiry() {
        expiryTimer?.invalidate()
        expiryTimer = nil
        guard let remaining else { return }
        let timer = Timer(timeInterval: remaining, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkExpiration() }
        }
        timer.tolerance = 1
        RunLoop.main.add(timer, forMode: .common)
        expiryTimer = timer
    }
}
