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
        // Phase 1: Ask for list of steps

        // Phase 2: Satisfy the steps one by one
    }

    func getStepsFromLLM(goal: String) async throws -> [String] {
        guard let (description, communication) = try await prepareInteractableDescriptions() else {
            print("Could not create description")
            return []
        }

        let prompt = String.build {
            """
You are my hands. I want to \(goal). You will be given some context, and I want you to write a high-level list of \
actions to take, as numbered bullet points such as "1. Open new tab". Try and use as few steps as possible. If the \
goal requires data that you cannot feasibly obtain from the names and descriptions of clickable buttons, such as \
reading contents of text fields, respond with "insufficient information"

"""
            description
        }

        // TODO: prompt the AI
        let response: String = """
1. do something
2. do something else
"""

        return response.split(separator: "\n").map { String($0) }
    }

    /// Creates a description of the element
    func prepareInteractableDescriptions() async throws -> (String, LLMCommunication)? {
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

        return (prompt, LLMCommunication(elementMap: elementMap))
    }
}

/// Holds and manages the data associated with the communication between BeMyHands and the LLM.
///
/// Acts as the interface for LLMs to take actions.
struct LLMCommunication {
    private var elementMap: [String: ActionableElement]

    init(elementMap: [String: ActionableElement]) {
        self.elementMap = elementMap
    }

    /// Executes an action on an element with a certain description. Handles data checks to make sure that the element
    /// exists and that the action is valid.
    func execute(action: String, onElementWithDescription elementDescription: String) async throws {
        guard action.hasPrefix("AX") && !action.contains(" ") else {
            throw LLMCommunicationError.actionFormatInvalid
        }

        guard let element = elementMap[elementDescription] else {
            throw LLMCommunicationError.elementNotFound
        }

        guard element.actions.contains(action) else {
            throw LLMCommunicationError.actionNotFound
        }

        try await element.element.performAction(action)
    }
}

enum LLMCommunicationError: Error {
    /// The action is not formatted properly
    case actionFormatInvalid

    /// Element was not found in the ``LLMCommunication`` instance
    case elementNotFound
    /// Action is not a valid action on the `Element` instance
    case actionNotFound
}
