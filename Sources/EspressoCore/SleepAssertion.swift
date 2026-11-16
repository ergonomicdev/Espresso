import Foundation
import IOKit.pwr_mgt

/// Something that can hold or release a "keep the Mac awake" assertion.
public protocol SleepAssertion: AnyObject {
    var isHeld: Bool { get }
    /// Returns `true` if the assertion is held after the call.
    @discardableResult func acquire() -> Bool
    func release()
}

/// Prevents idle display (and therefore system) sleep using an IOKit power assertion.
public final class PowerSleepAssertion: SleepAssertion {
    private var assertionID: IOPMAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
    private let reason: String

    public init(reason: String = "Espresso is keeping your Mac awake") {
        self.reason = reason
    }

    deinit {
        release()
    }

    public var isHeld: Bool {
        assertionID != IOPMAssertionID(kIOPMNullAssertionID)
    }

    @discardableResult
    public func acquire() -> Bool {
        guard !isHeld else { return true }
        var id = IOPMAssertionID(kIOPMNullAssertionID)
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &id
        )
        guard result == kIOReturnSuccess else { return false }
        assertionID = id
        return true
    }

    public func release() {
        guard isHeld else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = IOPMAssertionID(kIOPMNullAssertionID)
    }
}
