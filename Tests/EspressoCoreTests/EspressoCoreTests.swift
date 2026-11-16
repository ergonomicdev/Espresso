import Foundation
import Testing
@testable import EspressoCore

final class FakeAssertion: SleepAssertion {
    var isHeld = false
    var shouldFail = false
    var acquireCount = 0

    func acquire() -> Bool {
        acquireCount += 1
        if shouldFail { return false }
        isHeld = true
        return true
    }

    func release() { isHeld = false }
}

@MainActor
struct AwakeControllerTests {
    let assertion = FakeAssertion()
    let clock = Date(timeIntervalSince1970: 1_000)

    @Test func toggleActivatesAndDeactivates() {
        let controller = AwakeController(assertion: assertion)
        controller.toggle(defaultDuration: .indefinitely)
        #expect(controller.isActive)
        #expect(controller.endDate == nil)
        #expect(assertion.isHeld)

        controller.toggle(defaultDuration: .indefinitely)
        #expect(!controller.isActive)
        #expect(!assertion.isHeld)
    }

    @Test func timedActivationExpires() {
        var now = clock
        let controller = AwakeController(assertion: assertion, now: { now })
        controller.activate(for: .minutes(15))
        #expect(controller.endDate == clock.addingTimeInterval(900))
        #expect(controller.remaining == 900)

        now = clock.addingTimeInterval(899)
        controller.checkExpiration()
        #expect(controller.isActive)

        now = clock.addingTimeInterval(900)
        controller.checkExpiration()
        #expect(!controller.isActive)
        #expect(!assertion.isHeld)
        #expect(controller.endDate == nil)
    }

    @Test func reactivatingChangesDurationWithoutDoubleAcquire() {
        let controller = AwakeController(assertion: assertion, now: { clock })
        controller.activate(for: .hours(1))
        controller.activate(for: .indefinitely)
        #expect(controller.isActive)
        #expect(controller.endDate == nil)
        #expect(assertion.isHeld)
    }

    @Test func failedAssertionLeavesInactive() {
        assertion.shouldFail = true
        let controller = AwakeController(assertion: assertion)
        #expect(!controller.activate(for: .indefinitely))
        #expect(!controller.isActive)
    }
}

struct ActivationDurationTests {
    @Test func storageKeyRoundTrips() {
        for duration in ActivationDuration.allCases {
            #expect(ActivationDuration(storageKey: duration.storageKey) == duration)
        }
        #expect(ActivationDuration(storageKey: "bogus") == nil)
        #expect(ActivationDuration(storageKey: "0m") == nil)
    }

    @Test func remainingString() {
        #expect(TimeInterval(249).espressoRemainingString == "4:09")
        #expect(TimeInterval(3849).espressoRemainingString == "1:04:09")
        #expect(TimeInterval(0.2).espressoRemainingString == "0:01")
    }
}

@Test func realPowerAssertionAcquiresAndReleases() {
    let assertion = PowerSleepAssertion(reason: "Espresso unit test")
    #expect(assertion.acquire())
    #expect(assertion.isHeld)
    assertion.release()
    #expect(!assertion.isHeld)
}
