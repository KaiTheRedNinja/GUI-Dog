//
//  BeMyHandsApp.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import SwiftUI
import Access
import HandsBot

@main
struct BeMyHandsApp: App {
    @State var handsBot: HandsBot?
    @State var accessManager: AccessManager = .init()
    @State var overlayManager: OverlayManager = .init()

    var body: some Scene {
        MenuBarExtra {
            MenuExtraView(triggerLLM: triggerLLM)
        } label: {
            Image(systemName: "hand.wave.fill")
                .task {
                    accessManager.uiDelegate = overlayManager
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
            llmManager.accessibilityItemProvider = accessManager
            llmManager.uiDelegate = overlayManager
            llmManager.apiProvider = SecretsProvider()

            await llmManager.requestLLMAction(goal: goal)
            // remove the manager
            self.handsBot = nil
        }
    }
}

struct SecretsProvider: APIProvider {
    func getKey() -> String {
        Secrets.geminiKey
    }
}
