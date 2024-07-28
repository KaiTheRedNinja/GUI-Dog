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
    /// Determine if the goal is feasible. It expects the current access snapshot to be up-to-date.
    ///
    /// If this function exits without throwing, the goal is feasible.
    func determineGoalFeasibility(goal: String) async throws {
        var context: [String] = []

        for discoveryContentProvider in self.discoveryContentProviders {
            try await discoveryContentProvider.updateDiscoveryContext()
            let itemContext = try await discoveryContentProvider.getDiscoveryContext()
            if let itemContext {
                context.append(itemContext)
            }
        }

        let prompt = String.build {
"""
You are my hands. I want to \(goal). You will be given some context, and I want you to determine if this goal is \
possible using only these actions:

"""

            for stepCapabilityProvider in self.stepCapabilityProviders {
                " - " + stepCapabilityProvider.description
            }

"""

Note that you are UNABLE to execute any actions other than the ones listed above. You are able to read the titles and \
descriptions of buttons, including clickable non-button items like files.

If the goal is hypothetically possible with the given actions, respond with and only with "Possible". You do not need \
to explain how to achieve the goal.

If the goal is not hypothetically possible, respond with "Not Possible: ", followed by an explanation for why it is \
not possible to do with the given actions. Note that a goal is only not hypothetically possible if and only if it \
explicitly requires:
- Executing an action that cannot possibly be performed using the actions above, such as typing
- Context that is not available to you, such as "my phone number" or "alice's address"
- Reading text that is not a part of a button or clickable item like a tab, such as text from a label

"""

            for itemContext in context {
                itemContext
                "\n"
            }
        }

        logger.info("Prompt: \(prompt)")

        let response = try await llmProvider?.generateResponse(prompt: prompt, functions: nil)

        if let response, let text = response.text {
            logger.info("Response text: \(text)")

            if text.lowercased().starts(with: "possible") {
                return
            }

            throw LLMCommunicationError.goalImpossible(reason: text.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            throw LLMCommunicationError.textNotProvided
        }
    }
}
