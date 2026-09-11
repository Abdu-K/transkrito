import AppKit
import SwiftUI

/// A regular macOS app: dock icon, app menu, resizable main window, Settings on ⌘, (in-window page, same layout
/// as the Windows build), and a secondary menu bar item for status + hotkey while another app is in front.
/// LSUIElement is intentionally absent from Info.plist.
@main
struct TranskritoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var app = AppController()
    @State private var page: Page = .dictation

    var body: some Scene {
        Window("Transkrito", id: "main") {
            MainWindow(page: $page)
                .environment(app)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: Tokens.Layout.windowDefaultWidth, height: Tokens.Layout.windowDefaultHeight)
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .appSettings) {
                Button("Settings\u{2026}") { page = .settings; NSApp.activate(ignoringOtherApps: true) }
                    .keyboardShortcut(",", modifiers: .command)
            }
            CommandMenu("View") {
                Button("Dictation") { page = .dictation }.keyboardShortcut("1", modifiers: .command)
                Button("Dictionary") { page = .dictionary }.keyboardShortcut("2", modifiers: .command)
                Button("Settings") { page = .settings }.keyboardShortcut("3", modifiers: .command)
            }
            CommandMenu("Listening") {
                Button(app.actionLabel) { app.toggle() }
                    .disabled(app.isTranscribing)
                Divider()
                Text("\(app.holdToTalkVerb) \(app.settings.hotkey.display) anywhere")
            }
        }

        MenuBarExtra {
            MenuBarView(page: $page)
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
    @Binding var page: Page

    var body: some View {
        Text(app.status)
        Button("\(app.actionLabel) listening") { app.toggle() }
            .disabled(app.isTranscribing)
        Text("\(app.holdToTalkVerb) \(app.settings.hotkey.display)")
        Divider()
        Button("Open Transkrito") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
        Button("Settings\u{2026}") {
            page = .settings
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
        Button("Quit Transkrito") { NSApp.terminate(nil) }
    }
}
