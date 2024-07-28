//
//  BeMyHandsApp.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import SwiftUI
import Access
import Element
import HandsBot
import GoogleGenerativeAI
import Input
import OSLog

private let logger = Logger(subsystem: #fileID, category: "BeMyHands")

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        // save preferences
        PreferencesManager.global.save()
        logger.info("Saved preferences")
    }
}

@main
struct BeMyHandsApp: App {
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate

    @State var handsBot: HandsBot?
    @State var accessManager: AccessManager = .init()
    @State var overlayManager: OverlayManager = .init()

    @Environment(\.openWindow)
    var openWindow

    var body: some Scene {
        WindowGroup(id: "setupWindow") {
            SetupView(setupCallback: { Task { await setup() } })
        }
        .windowStyle(HiddenTitleBarWindowStyle())

        Settings {
            Text("Not Done Yet")
        }

        MenuBarExtra {
            MenuExtraView(triggerLLM: triggerLLM)
        } label: {
            Image(systemName: "hand.wave.fill")
                .task {
                    accessManager.uiDelegate = overlayManager
                    await setup()
                }
        }
    }

    func setup() async {
        guard Element.checkProcessTrustedStatus() else {
            logger.info("No permissions!")
            return
        }

        await accessManager.setup()

        Input.shared.browseModeEnabled = true

        Input.shared.bindKey(
            browseMode: true,
            controlModifier: true,
            optionModifier: true,
            commandModifier: true,
            key: .keyboardL,
            action: triggerLLM
        )
    }

    func triggerLLM() {
        // create the hands bot if it doesn't exist
        guard handsBot == nil else { return }

        Task {
            let goal = await overlayManager.requestGoal()

            guard let goal else {
                // TODO: inform the user that the goal is empty
                return
            }

            let llmManager = HandsBot()
            self.handsBot = llmManager
            llmManager.discoveryContentProviders = [accessManager]
            llmManager.stepCapabilityProviders = [accessManager, AppOpen.global]
            llmManager.uiDelegate = overlayManager
            llmManager.llmProvider = GeminiLLMProvider.global

            await llmManager.requestLLMAction(goal: goal)
            // remove the manager
            self.handsBot = nil
        }
    }
}
