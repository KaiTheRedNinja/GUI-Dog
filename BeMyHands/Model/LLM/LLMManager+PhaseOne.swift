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
        let appName = await accessibilityItemProvider.getCurrentAppName()
        let focusedDescription = await accessibilityItemProvider.getFocusedElementDescription()

        let prompt = String.build {
            """
You are my hands. I want to \(goal). You will be given some context, and I want you to write a high-level list of \
actions to take, as numbered bullet points such as "1. Open new tab". Try and use as few steps as possible, and rely \
more on buttons on the screen than in the menu bar.

Note that you are NOT able to type, only press buttons or open items. If the goal requires data that you cannot \
feasibly obtain from the names and descriptions of clickable buttons, such as reading contents of text fields, or \
requires you to perform a type, drag, or other unsupported action, respond with "insufficient information".

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

        let model = GenerativeModel(name: "gemini-1.5-flash", apiKey: Secrets.geminiKey)
        let response = try await model.generateContent(prompt)
        if let text = response.text {
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
