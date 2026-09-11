import AppKit
import SwiftUI

/// A regular macOS app: dock icon, app menu, resizable main window, Settings on ⌘, and a secondary menu bar item
/// for status + hotkey while another app is in front. LSUIElement is intentionally absent from Info.plist.
@main
struct TranskritoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var app = AppController()

    var body: some Scene {
        Window("Transkrito", id: "main") {
            MainWindow()
                .environment(app)
        }
        .defaultSize(width: Tokens.Layout.windowDefaultWidth, height: Tokens.Layout.windowDefaultHeight)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Listening") {
                Button(app.actionLabel) { app.toggle() }
                    .disabled(app.isTranscribing)
                Divider()
                Text("Global hotkey: \(app.settings.hotkey.display)")
            }
        }

        Settings {
            SettingsView()
                .environment(app)
        }

        MenuBarExtra {
            MenuBarView()
                .environment(app)
        } label: {
            Image(systemName: menuBarSymbol)
        }
    }

    private var menuBarSymbol: String {
        switch app.state {
        case .idle: return "waveform"
        case .listening: return "waveform.circle.fill"
        case .transcribing: return "waveform.badge.magnifyingglass"
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Closing the window keeps the app (and its hotkey) alive; Quit lives in the app menu and menu bar item.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { NSApp.windows.first { $0.identifier?.rawValue.hasPrefix("main") == true }?.makeKeyAndOrderFront(nil) }
        return true
    }
}

/// Menu bar item: status line, Start/Stop (hotkey shown), Open Transkrito, Settings…, Quit.
struct MenuBarView: View {
    @Environment(AppController.self) private var app
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Text(app.status)
        Button("\(app.actionLabel) Listening") { app.toggle() }
            .disabled(app.isTranscribing)
        Text(app.settings.hotkey.display)
        Divider()
        Button("Open Transkrito") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
        Button("Settings\u{2026}") {
            openSettings()
            NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
        Button("Quit Transkrito") { NSApp.terminate(nil) }
    }
}
