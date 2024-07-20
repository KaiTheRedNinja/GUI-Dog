//
//  LLMManager+PhaseOne.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 19/7/24.
//

import Foundation
import GoogleGenerativeAI

extension LLMManager {
    /// Obtains a list of steps from the LLM. It expects the current access snapshot to be up-to-date.
    func getStepsFromLLM(goal: String) async throws -> [String] {
        let appName = accessibilityItemProvider.getCurrentAppName()
        let focusedDescription = accessibilityItemProvider.getFocusedElementDescription()

        let prompt = String.build {
            """
You are my hands. I want to \(goal). You will be given some context, and I want you to write a high-level list of \
actions to take, as numbered bullet points such as "1. Open new tab". Try and use as few steps as possible, and rely \
only on buttons on the screen.

Note that you are NOT able to type, only press buttons. If the goal requires data that you cannot feasibly obtain \
from the names and descriptions of clickable buttons, such as reading text, or requires you to perform a drag, typing, \
or other unsupported action, respond with "insufficient information".

"""

            if let appName {
                "The focused app is \(appName)"
            } else {
                "There is no focused app"
            }

            "\n"

            if let focusedDescription {
                "The focused element is \(focusedDescription)"
            } else {
                "There is no focused element"
            }
        }

        print("Prompt: \(prompt)")

        let model = GenerativeModel(name: "gemini-1.5-flash", apiKey: apiProvider.getKey())
        let response = try await model.generateContent(prompt)
        if let text = response.text {
            if text.contains("insufficient information") {
                // TODO: figure out why this triggers but the one below doesn't
                print("bruh why does it contain insufficient info")
                throw LLMCommunicationError.insufficientInformation
            }
            if text.trimmingCharacters(in: .whitespacesAndNewlines) != "insufficient information" {
                print("Response text: \(text)")
                return text.split(separator: "\n").map { String($0) }
            } else {
                throw LLMCommunicationError.insufficientInformation
            }
        } else {
            throw LLMCommunicationError.textNotProvided
        }
    }
}
