//
//  HandsBot+PhaseOne.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 19/7/24.
//

import Foundation
import OSLog

private let logger = Logger(subsystem: #fileID, category: "HandsBot")

extension HandsBot {
    /// Obtains a list of steps from the LLM. It expects the current access snapshot to be up-to-date.
    func getStepsFromLLM(goal: String) async throws -> [String] {
        var context: [String] = []

        for discoveryContentProvider in self.discoveryContentProviders {
            try await discoveryContentProvider.updateContext()
            let itemContext = try await discoveryContentProvider.getContext()
            if let itemContext {
                context.append(itemContext)
            }
        }

        let prompt = String.build {
"""
You are my hands. I want to \(goal). You will be given some context, and I want you to write a high-level list of \
actions to take, as numbered bullet points such as "1. Open new tab". Try and use as few steps as possible. The only \
actions you will have available to you are:

"""

            for stepCapabilityProvider in self.stepCapabilityProviders {
                " - " + stepCapabilityProvider.description
            }

"""

Note that you are UNABLE to execute any actions other than the ones listed above. You are able to read the titles and \
descriptions of buttons, including clickable non-button items like files.

Respond with a list of steps, where each step should match one of the above actions that you can perform, such as \
"Click on New Tab button" or "Open Finder". Note that you only need to outline high-level steps, more details, context \
and instructions will be provided when each step is executed.

When executing each step, you will be given additional context, such as the names and descriptions of clickable buttons.

If the goal EXPLICITLY requires:
- Executing an action that cannot possibly be performed using the actions above, such as typing
- Context that is not available to you, such as "my phone number" or "alice's address"
- Reading text that is not a part of a button or clickable item like a tab, such as text from a label
respond with a reason and end with "insufficient information".

If not, respond with the list of steps.

"""

            for itemContext in context {
                itemContext
                "\n"
            }
        }

        logger.info("Prompt: \(prompt)")

        let response = try await llmProvider.generateResponse(prompt: prompt, functions: nil)

        if let text = response.text {
            logger.info("Response text: \(text)")
            if text.lowercased().contains("insufficient information") {
                throw LLMCommunicationError.insufficientInformation
            }
            return text.split(separator: "\n").map { String($0) }
        } else {
            throw LLMCommunicationError.textNotProvided
        }
    }
}
