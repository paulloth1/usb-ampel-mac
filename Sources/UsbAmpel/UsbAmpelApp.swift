import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct UsbAmpelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var ampel = AmpelController()

    var body: some Scene {
        WindowGroup("USB-Ampel") {
            ContentView()
                .environmentObject(ampel)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandMenu("Light") {
                Button("Toggle Red") { ampel.toggle(.red) }
                    .keyboardShortcut("1", modifiers: .command)
                Button("Toggle Yellow") { ampel.toggle(.yellow) }
                    .keyboardShortcut("2", modifiers: .command)
                Button("Toggle Green") { ampel.toggle(.green) }
                    .keyboardShortcut("3", modifiers: .command)
                Divider()
                Button("All Off") { ampel.allOff() }
                    .keyboardShortcut("0", modifiers: .command)
            }
        }
    }
}
