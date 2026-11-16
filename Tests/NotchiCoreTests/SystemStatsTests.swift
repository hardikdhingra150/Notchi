import Foundation
import Testing
@testable import NotchiCore

@Suite struct SystemStatsTests {
    typealias C = SystemStats.Counters

    @Test func ratesFromTwoSamples() {
        let a = C(cpuBusy: 100, cpuTotal: 400, netIn: 1_000, netOut: 500, time: 10)
        let b = C(cpuBusy: 150, cpuTotal: 500, netIn: 3_000, netOut: 1_500, time: 12)
        let r = SystemStats.rates(from: a, to: b)
        #expect(r.cpu == 0.5)
        #expect(r.down == 1_000)
        #expect(r.up == 500)
    }

    @Test func countersThatResetCountAsZero() {
        let a = C(cpuBusy: 100, cpuTotal: 400, netIn: 9_000, netOut: 9_000, time: 10)
        let b = C(cpuBusy: 10, cpuTotal: 40, netIn: 10, netOut: 10, time: 11)
        let r = SystemStats.rates(from: a, to: b)
        #expect(r.cpu == 0)
        #expect(r.down == 0)
        #expect(r.up == 0)
    }

    @Test func realReadingsAreSane() {
        let first = SystemStats.sample(since: nil)
        let (s, _) = SystemStats.sample(since: first.counters)
        #expect((0...1).contains(s.cpu))
        #expect(s.memoryTotal > 1_000_000_000)
        #expect(s.memoryUsed > 0 && s.memoryUsed <= s.memoryTotal)
        #expect(s.diskTotal > 0 && s.diskFree > 0 && s.diskFree <= s.diskTotal)
    }
}
