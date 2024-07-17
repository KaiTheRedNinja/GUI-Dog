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
    func requestLLMAction(goal: String) async {
        guard communication == nil else {
            print("Could not request LLM: LLM already running")
            // TODO: fail elegantly
            return
        }

        // Create the object
        let communication = LLMCommunication()
        self.communication = communication

        await overlayManager.show()
        await overlayManager.update(with: communication.state)

        defer {
            self.communication = nil
            DispatchQueue.main.async { @MainActor in
                self.overlayManager.update(with: communication.state)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { @MainActor in
                self.overlayManager.hide()
            }
        }

        // retake snapshot
        do {
            try await takeAccessSnapshot()
        } catch {
            print("Could not get access snapshot")
            communication.updateState(toError: .init(error))
            return
        }

        // Phase 1: Ask for list of steps
        let steps: [String]
        do {
            steps = try await getStepsFromLLM(goal: goal)
        } catch {
            print("Could not get steps from LLM")
            communication.updateState(toError: .init(error))
            return
        }

        guard !steps.isEmpty else {
            print("No steps given")
            communication.updateState(toError: .emptyResponse)
            return
        }

        let stepCount = steps.count
        communication.setup(withGoal: goal, steps: steps.filter { !$0.isEmpty })

        await overlayManager.update(with: communication.state)

        // Phase 2: Satisfy the steps one by one
        while case let .step(step) = communication.state.commState, step.currentStep < stepCount {
            // retake the snapshot
            do {
                try await takeAccessSnapshot()
            } catch {
                print("Could not get access snapshot")
                communication.updateState(toError: .init(error))
                return
            }

            // note that this MAY result in infinite loops. The new context may still be
            // targeting the same step, because a single step may require multiple `executeStep`
            // calls
            let newContext: ActionStepContext
            do {
                newContext = try await executeStep(goal: goal, steps: steps, context: step)
            } catch {
                print("Could not execute the step")
                communication.updateState(toError: .init(error))
                return
            }

            // update the steps
            communication.updateState(toStep: newContext)
            await overlayManager.update(with: communication.state)
        }

        await overlayManager.update(
            with: .init(
                goal: communication.state.goal,
                steps: communication.state.steps,
                commState: .complete
            )
        )

        // Done!
        // TODO: somehow notify the user that the action has been completed
    }

    /// Creates a description of the element
    func prepareInteractableDescriptions() async throws -> (String, [String: ActionableElement]) {
        guard let accessSnapshot else {
            throw LLMCommunicationError.accessSnapshotNotFound
        }

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

            let uuid = UUID().uuidString
            let desc = role + ": " + description + ": " + uuid
            elementMap[uuid] = element

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
