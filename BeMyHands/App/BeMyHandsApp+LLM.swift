//
//  BeMyHandsApp+LLM.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 29/7/24.
//

import Access
import Element
import HandsBot
import GoogleGenerativeAI
import Input
import Output
import OSLog

private let logger = Logger(subsystem: #fileID, category: "BeMyHands")

extension BeMyHandsApp {
    func setup() async {
        Output.shared.isEnabled = PreferencesManager.global.userVisionStatus.useAudioCues

        guard Element.checkProcessTrustedStatus() else {
            logger.info("No permissions!")
            return
        }

        await accessManager.setup()

        Input.shared.browseModeEnabled = true
        Input.shared.swallowTapEvents = false

        Input.shared.bindKey(
            PreferencesManager.global.keyboardShortcut,
            action: triggerLLM
        )
    }

    func triggerLLM() {
        // if llm is in progress, abort it and return
        guard llmInProgress == false else {
            Task {
                await overlayManager.abortGoalRequest()
                await handsBot?.cancel()
                handsBot = nil
                llmInProgress = false
                overlayManager.hide()
            }

            Output.shared.announce("LLM operation cancelled")

            return
        }

        Task {
            llmInProgress = true

            let goal = await overlayManager.requestGoal()

            guard let goal else {
                // TODO: inform the user that the goal is empty
                return
            }

            let llmManager = HandsBot()
            self.handsBot = llmManager
            llmManager.discoveryContentProviders = [accessManager]
            llmManager.stepCapabilityProviders = [
                accessManager,
                AppOpen.global
//                KeyboardProvider.global
            ]
            llmManager.uiDelegate = overlayManager
            llmManager.llmProvider = GeminiLLMProvider.global

            await llmManager.requestLLMAction(goal: goal)
            // remove the manager
            self.handsBot = nil

            llmInProgress = false
        }
    }
}
