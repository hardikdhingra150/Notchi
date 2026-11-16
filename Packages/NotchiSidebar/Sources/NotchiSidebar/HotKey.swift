import Carbon.HIToolbox
import Foundation

/// A system-wide keyboard shortcut. Carbon's hot keys need no Accessibility permission.
@MainActor
final class HotKey {
    private var ref: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let action: () -> Void
    private static var actions: [UInt32: () -> Void] = [:]
    private static var nextID: UInt32 = 1
    private let id: UInt32

    /// keyCode is a virtual key (kVK_ANSI_N); modifiers are Carbon flags (controlKey | optionKey).
    init?(keyCode: Int, modifiers: Int, action: @escaping () -> Void) {
        self.action = action
        id = Self.nextID
        Self.nextID += 1
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hk = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hk)
            let id = hk.id
            DispatchQueue.main.async { MainActor.assumeIsolated { HotKey.actions[id]?() } }
            return noErr
        }, 1, &spec, nil, &handler)
        guard status == noErr else { return nil }
        let hkID = EventHotKeyID(signature: OSType(0x4E544849), id: id)   // "NTHI"
        guard RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers), hkID, GetApplicationEventTarget(), 0, &ref) == noErr else {
            if let handler { RemoveEventHandler(handler) }
            return nil
        }
        Self.actions[id] = action
    }

    func unregister() {
        if let ref { UnregisterEventHotKey(ref) }
        if let handler { RemoveEventHandler(handler) }
        Self.actions[id] = nil
        ref = nil; handler = nil
    }
}
