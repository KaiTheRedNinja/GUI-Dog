//
//  PhaseOne.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 16/7/24.
//

import Foundation
import GoogleGenerativeAI

extension AccessManager {
    func getStepsFromLLM(goal: String) async throws -> [String] {
        guard let accessSnapshot else {
            print("Could not access snapshot")
            throw LLMCommunicationError.accessSnapshotNotFound
        }

        let prompt = try await String.build {
            """
You are my hands. I want to \(goal). You will be given some context, and I want you to write a high-level list of \
actions to take, as numbered bullet points such as "1. Open new tab". Try and use as few steps as possible, and rely \
more on buttons on the screen than in the menu bar.

Note that you are NOT able to type, only press buttons or open items. If the goal requires data that you cannot \
feasibly obtain from the names and descriptions of clickable buttons, such as reading contents of text fields, or \
requires you to perform a type, drag, or other unsupported action, respond with "insufficient information".

"""

            if let focusedAppName = accessSnapshot.focusedAppName {
                "The focused app is \(focusedAppName)"
            } else {
                "There is no focused app"
            }

            "\n"

            if let focus = accessSnapshot.focus {
                "The focused element is \(try await focus.getComprehensiveDescription())"
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
