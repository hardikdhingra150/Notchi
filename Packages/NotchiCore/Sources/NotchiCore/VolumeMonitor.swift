import AudioToolbox
import CoreAudio
import Foundation

/// Watches the default output device's volume and mute state (public CoreAudio APIs).
@MainActor
public final class VolumeMonitor {
    private let bus: EventBus
    private var device = AudioObjectID(kAudioObjectUnknown)
    private var last: (Double, Bool)?
    private let queue = DispatchQueue.main

    public init(bus: EventBus) { self.bus = bus }

    public func start() {
        var addr = Self.address(kAudioHardwarePropertyDefaultOutputDevice, scope: kAudioObjectPropertyScopeGlobal)
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &addr, queue) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.bind() }
        }
        bind()
    }

    private var listener: AudioObjectPropertyListenerBlock?

    private func bind() {
        if device != kAudioObjectUnknown, let l = listener {
            for sel in [kAudioHardwareServiceDeviceProperty_VirtualMainVolume, kAudioDevicePropertyMute] {
                var a = Self.address(sel)
                AudioObjectRemovePropertyListenerBlock(device, &a, queue, l)
            }
        }
        device = Self.defaultOutput()
        guard device != kAudioObjectUnknown else { return }
        let l: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            MainActor.assumeIsolated { self?.changed() }
        }
        listener = l
        for sel in [kAudioHardwareServiceDeviceProperty_VirtualMainVolume, kAudioDevicePropertyMute] {
            var a = Self.address(sel)
            AudioObjectAddPropertyListenerBlock(device, &a, queue, l)
        }
        last = read()  // don't show the HUD just because we started listening
    }

    private func changed() {
        guard let now = read() else { return }
        if let last, abs(last.0 - now.0) < 0.001, last.1 == now.1 { return }
        last = now
        bus.post(.volume(level: now.0, muted: now.1))
    }

    private func read() -> (Double, Bool)? {
        var vol = Float32(0), size = UInt32(MemoryLayout<Float32>.size)
        var a = Self.address(kAudioHardwareServiceDeviceProperty_VirtualMainVolume)
        guard AudioObjectGetPropertyData(device, &a, 0, nil, &size, &vol) == noErr else { return nil }
        var mute = UInt32(0); size = UInt32(MemoryLayout<UInt32>.size)
        var m = Self.address(kAudioDevicePropertyMute)
        let muted = AudioObjectGetPropertyData(device, &m, 0, nil, &size, &mute) == noErr && mute != 0
        return (Double(vol), muted)
    }

    private static func defaultOutput() -> AudioObjectID {
        var id = AudioObjectID(kAudioObjectUnknown), size = UInt32(MemoryLayout<AudioObjectID>.size)
        var a = address(kAudioHardwarePropertyDefaultOutputDevice, scope: kAudioObjectPropertyScopeGlobal)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &a, 0, nil, &size, &id)
        return id
    }

    private static func address(_ sel: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioDevicePropertyScopeOutput) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: sel, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }
}
