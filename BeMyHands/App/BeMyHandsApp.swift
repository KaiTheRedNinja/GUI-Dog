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
import OSLog

private let logger = Logger(subsystem: #fileID, category: "BeMyHands")

@main
struct BeMyHandsApp: App {
    @State var handsBot: HandsBot?
    @State var accessManager: AccessManager = .init()
    @State var overlayManager: OverlayManager = .init()

    @Environment(\.openWindow)
    var openWindow

    var body: some Scene {
        WindowGroup(id: "setupWindow") {
            Text("Setting Up")
        }

        MenuBarExtra {
            MenuExtraView(triggerLLM: triggerLLM)
        } label: {
            Image(systemName: "hand.wave.fill")
                .task {
                    accessManager.uiDelegate = overlayManager

                    guard Element.confirmProcessTrustedStatus() else {
                        logger.info("No permissions!")
                        openWindow(id: "setupWindow")
                        return
                    }

                    await accessManager.setup()
                }
        }
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
