import Foundation
import Sparkle

/// Sparkle auto-updates. The feed lives on GitHub Releases and every update is
/// signed with Notchi's own free EdDSA key (no paid Apple certificate needed).
/// Builds without a public key in Info.plist (local dev builds) keep the updater off.
@MainActor
final class Updater {
    private let controller: SPUStandardUpdaterController?

    init() {
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? ""
        let feed = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String ?? ""
        if key.isEmpty || feed.isEmpty {
            controller = nil
        } else {
            controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        }
    }

    var isEnabled: Bool { controller != nil }

    func checkForUpdates() {
        controller?.checkForUpdates(nil)
    }

    /// Settings toggle: automatic background checks (on by default, can be turned off).
    var automaticallyChecks: Bool {
        get { controller?.updater.automaticallyChecksForUpdates ?? false }
        set { controller?.updater.automaticallyChecksForUpdates = newValue }
    }
}
