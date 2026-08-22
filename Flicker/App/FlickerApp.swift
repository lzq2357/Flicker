//
//  FlickerApp.swift
//  Flicker
//
//  Container app entry point.
//

import SwiftUI

@main
struct FlickerApp: App {
    static let mainWindowID = "main"
    @StateObject private var store = AppEntryStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        Window("Flicker", id: Self.mainWindowID) {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 560, minHeight: 420)
                .onAppear {
                    // 捕获场景动作到桥接单例；窗口关闭后闭包仍有效。
                    AppActions.shared.openMainWindow = { [self] in
                        openWindow(id: Self.mainWindowID)
                    }
                    AppActions.shared.openSettings = {
                        // openSettings 环境变量是 macOS 14+ API，13 上没有；
                        // showSettingsWindow: 选择器在 13/14 都能打开 SwiftUI Settings 场景。
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    }
                }
                .onOpenURL { url in
                    URLOpener.handle(url)
                }
                .background(WindowManagementConfigurator())
        }
        .windowToolbarStyle(.unified)
        .defaultSize(width: 720, height: 520)

        Settings {
            SettingsView()
        }
    }
}

private struct WindowManagementConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                AppSettings.shared.configureWindowManagementVisibility(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                AppSettings.shared.configureWindowManagementVisibility(window)
            }
        }
    }
}
