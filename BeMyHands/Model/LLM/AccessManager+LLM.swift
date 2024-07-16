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
        communication.setup(withGoal: goal, steps: steps.filter { !$0.isEmpty })

        // Phase 2: Satisfy the steps one by one
        var success: Bool = true
        while communication.stepContext.currentStep < stepCount {
            // retake the snapshot
            try await takeAccessSnapshot()

            // note that this MAY result in infinite loops. The new context may still be
            // targeting the same step, because a single step may require multiple `executeStep`
            // calls
            let newContext = try await executeStep(context: communication.stepContext)

            // if the new context is nil, that means something went wrong and some data turned
            // up empty. TODO: throw instead of optionals
            guard let newContext else {
                print("Failed due to unknown reasons")
                success = false
                break
            }

            // update the steps
            communication.updateStepContext(to: newContext)
        }

        print("Success: \(success)")

        // Done!
        // TODO: somehow notify the user that the action has been completed
    }

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

            /*
            "\n"

            "The menu bar items are:"
            // only menu item and menu bar item should be shown here
            for menuBarItem in menuBarItems {
                try await descriptionFor(element: menuBarItem)
            }
             */
        }

        return (prompt, elementMap)
    }
}
