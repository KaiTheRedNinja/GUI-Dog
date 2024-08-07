//
//  GUIDogApp.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 8/7/24.
//

import SwiftUI
import HandsBot
import OSLog

private let logger = Logger(subsystem: #fileID, category: "GUIDog")

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        // save preferences
        PreferencesManager.global.save()
        logger.info("Saved preferences")
    }
}

@main
struct GUIDogApp: App {
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate

    @State var handsBot: HandsBot?
    @State var llmInProgress: Bool = false
    @State var accessManager: AccessManager = .init()
    @State var overlayManager: OverlayManager = .init()

    @Environment(\.openWindow)
    var openWindow

    var body: some Scene {
        WindowGroup(id: "setupWindow") {
            SetupView(setupCallback: { Task { await setup() } })
        }
        .windowStyle(HiddenTitleBarWindowStyle())

        WindowGroup(id: "settingsWindow") {
            SettingsView()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuExtraView(triggerLLM: triggerLLM)
        } label: {
            Image(systemName: "pawprint.fill")
                .task {
                    accessManager.uiDelegate = overlayManager
                    await setup()
                }
        }
    }
}
