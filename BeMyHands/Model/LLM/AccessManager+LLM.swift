//
//  AccessManager+LLM.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 15/7/24.
//

import Foundation
import Element
import GoogleGenerativeAI

extension AccessManager {
    /// Requests actions from the Gemini API based on a request and the current `accessSnapshot`
    func requestLLMAction(goal: String) async throws {
        // Create the object
        let communication = LLMCommunication()
        self.communication = communication

        // Phase 1: Ask for list of steps
        let steps = try await getStepsFromLLM(goal: goal)
        let stepCount = steps.count
        communication.setup(withGoal: goal, steps: steps)

        // Phase 2: Satisfy the steps one by one
        while communication.stepContext.currentStep < stepCount {
            let newContext = try await executeStep(context: communication.stepContext)
            communication.updateStepContext(to: newContext)
        }

        // Done!
        // TODO: somehow notify the user that the action has been completed
    }

    // MARK: Phase 1
    func getStepsFromLLM(goal: String) async throws -> [String] {
        guard let accessSnapshot else {
            print("Could not access snapshot")
            return []
        }

        let prompt = try await String.build {
            """
You are my hands. I want to \(goal). You will be given some context, and I want you to write a high-level list of \
actions to take, as numbered bullet points such as "1. Open new tab". Try and use as few steps as possible. If the \
goal requires data that you cannot feasibly obtain from the names and descriptions of clickable buttons, such as \
reading contents of text fields, respond with "insufficient information"

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

        // TODO: prompt the AI
        let response: String = """
1. do something
2. do something else
"""

        return response.split(separator: "\n").map { String($0) }
    }

    // MARK: Phase 2

    func executeStep(context: ActionStepContext) async throws -> ActionStepContext {
        // 1. Gather context
        // 2. Request the AI
        // 3. Execute the actions
        // 4. If the AI says that the step has not been completed, then recurse

        fatalError("Not yet implemented")
    }

    // MARK: Utilities

    /// Creates a description of the element
    func prepareInteractableDescriptions() async throws -> (String, [String: ActionableElement])? {
        guard let accessSnapshot else { return nil }

        let screenElements = accessSnapshot.actionableItems.filter { !$0.isMenuBarItem }
        var menuBarItems: [ActionableElement] = []

        for item in accessSnapshot.actionableItems {
            guard item.isMenuBarItem else { continue }
            guard try await item.element.roleMatches(oneOf: [
                .menuItem,
                .menuBarItem
            ]) else { continue }

            menuBarItems.append(item)
        }

        var elementMap: [String: ActionableElement] = [:]

        func descriptionFor(element: ActionableElement) async throws -> String {
            let role = try await element.element.getAttribute(.roleDescription) as? String
            let description = try await element.element.getDescription()
            let actions = element.actions

            guard let role, let description else { return "" }

            let desc = role + ": " + description
            elementMap[desc] = element

            return try await String.build {
                " - " + desc

                for action in actions where action != "AXCancel" {
                    let description = try await element.element.describeAction(action)
                    "    - " + action + (
                        description == nil
                        ? ""
                        : ": " + description!
                    )
                }
            }
        }

        let prompt = try await String.build {
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

            "\n"

            "The actionable elements are:"
            for actionableItem in screenElements {
                try await descriptionFor(element: actionableItem)
            }

            "\n"

            "The menu bar items are:"
            // only menu item and menu bar item should be shown here
            for menuBarItem in menuBarItems {
                try await descriptionFor(element: menuBarItem)
            }
        }

        return (prompt, elementMap)
    }
}
