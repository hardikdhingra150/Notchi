import Testing
@testable import NotchiCore

@Suite struct LevelStepTests {
    @Test func stepsInSixteenths() {
        #expect(LevelStep.next(0.5, direction: 1, fine: false) == 0.5625)
        #expect(LevelStep.next(0.5, direction: -1, fine: false) == 0.4375)
    }

    @Test func snapsOffGridValuesToTheNextStep() {
        // 0.63 is closest to 10/16, so one press up lands on 11/16
        #expect(LevelStep.next(0.63, direction: 1, fine: false) == 11.0 / 16.0)
    }

    @Test func staysInRange() {
        #expect(LevelStep.next(1, direction: 1, fine: false) == 1)
        #expect(LevelStep.next(0, direction: -1, fine: true) == 0)
    }

    @Test func fineStepsAreQuarterSize() {
        #expect(LevelStep.next(0.5, direction: 1, fine: true) == 0.5 + 1.0 / 64.0)
    }
}
