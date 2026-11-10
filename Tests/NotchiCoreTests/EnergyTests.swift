import Testing
@testable import NotchiCore

@MainActor
@Suite struct EnergyRuleTests {
    typealias G = EnergyGovernor
    let rules = G.Rules()

    @Test func fullSpeedWhenPluggedIn() {
        let b = G.budget(for: .init(), rules: rules)
        #expect(b.fps == 30)
        #expect(b.reason == nil)
    }

    @Test func batteryUsesTheUsersChoice() {
        #expect(G.budget(for: .init(onBattery: true, batteryLevel: 0.8), rules: rules).fps == 15)
        #expect(G.budget(for: .init(onBattery: true, batteryLevel: 0.8), rules: .init(batteryFPS: 0)).fps == 0)
        let full = G.budget(for: .init(onBattery: true, batteryLevel: 0.8), rules: .init(batteryFPS: 30))
        #expect(full.fps == 30)
        #expect(full.reason == nil)
        #expect(G.budget(for: .init(onBattery: true, batteryLevel: 0.8), rules: .init(batteryFPS: 999)).fps == 30)
    }

    @Test func pausesOnLowBatteryUnlessTurnedOff() {
        let low = G.Inputs(onBattery: true, batteryLevel: 0.2)
        #expect(G.budget(for: low, rules: rules).fps == 0)
        #expect(G.budget(for: low, rules: rules).reason == "battery below 20%")
        #expect(G.budget(for: low, rules: .init(pauseWhenLow: false)).fps == 15)
        // a low battery that's charging is fine
        #expect(G.budget(for: .init(onBattery: false, batteryLevel: 0.05), rules: rules).fps == 30)
    }

    @Test func lowPowerModeAndHeatAlwaysWin() {
        let generous = G.Rules(batteryFPS: 30, pauseWhenLow: false)
        #expect(G.budget(for: .init(lowPower: true), rules: generous).reason == "Low Power Mode")
        #expect(G.budget(for: .init(thermal: .serious), rules: generous).fps == 0)
        #expect(G.budget(for: .init(thermal: .critical), rules: generous).fps == 0)
        let warm = G.budget(for: .init(thermal: .fair), rules: generous)
        #expect(warm.fps == 15)
        #expect(warm.reason == "your Mac is warm")
    }

    @Test func reduceMotionPassesThrough() {
        #expect(G.budget(for: .init(reduceMotion: true), rules: rules).reduceMotion)
    }
}
