//
//  LLMManager.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 19/7/24.
//

import Foundation
import Access

/// A class that facilitates the conversation with an LLM. This manager should be RESET
/// for every conversation.
class LLMManager {
    /// The accessibility item provider. Note that this should be defined as soon as possible before
    /// any other methods are called.
    weak var accessibilityItemProvider: AccessibilityItemProvider!

    /// The UI delegate, which is informed of when the UI should update to reflect the manager's
    /// internal state. Optional.
    weak var uiDelegate: LLMDisplayDelegate?

    /// The current state
    var state: LLMState = .zero

    /// Creates a blank `LLMManager`
    init(
        accessibilityItemProvider: AccessibilityItemProvider! = nil,
        uiDelegate: LLMDisplayDelegate? = nil
    ) {
        self.accessibilityItemProvider = accessibilityItemProvider
        self.uiDelegate = uiDelegate
    }

    /// Requests actions from the Gemini API based on a request and the current `accessSnapshot`
    func requestLLMAction(goal: String) async {
        guard state == .zero else {
            print("Could not request LLM: LLM already running")
            // TODO: fail elegantly
            return
        }
        state = .init(goal: goal, steps: [])

        // Create the object
        await uiDelegate?.show()
        await uiDelegate?.update(state: state)

        // After everything, update the UI then hide it
        defer {
            Task {
                await self.uiDelegate?.update(state: state)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { @MainActor in
                Task {
                    await self.uiDelegate?.hide()
                }
            }
        }

        // update catalog
        do {
            try await accessibilityItemProvider.updateAccessibilityObjects()
        } catch {
            print("Could not get access snapshot")
            updateState(toError: .init(error))
            return
        }

        // Phase 1: Ask for list of steps
        let steps: [String]
        do {
            steps = try await getStepsFromLLM(goal: goal)
        } catch {
            print("Could not get steps from LLM")
            updateState(toError: .init(error))
            return
        }

        guard !steps.isEmpty else {
            print("No steps given")
            updateState(toError: .emptyResponse)
            return
        }

        setup(withGoal: goal, steps: steps.filter { !$0.isEmpty })

        await uiDelegate?.update(state: state)

        // Phase 2: Satisfy the steps one by one
        while true {
            // determine if we're done here
            let isDone: Bool // flag
            switch state.overallState {
            case .complete, .error:
                isDone = true
            default:
                isDone = false
            }
            if isDone { break }

            // obtain information about the current step
            let currentStep = state.currentStep

            let stepContext = switch currentStep.state {
            case .working(let actionStepContext):
                actionStepContext
            default:
                // TODO: fail elegantly here
                fatalError("Internal inconsistency")
            }

            // retake the snapshot
            do {
                try await accessibilityItemProvider.updateAccessibilityObjects()
            } catch {
                print("Could not get access snapshot")
                updateState(toError: .init(error))
                return
            }

            // note that this MAY result in infinite loops. The new context may still be
            // targeting the same step, because a single step may require multiple `executeStep`
            // calls
            let actionStatus: StepExecutionStatus
            do {
                actionStatus = try await executeStep(state: state, context: stepContext)
            } catch {
                print("Could not execute the step")
                updateState(toError: .init(error))
                return
            }

            // update the steps
            switch actionStatus {
            case .incomplete(let newContext):
                updateState(toStep: newContext)
            case .complete:
                updateStateToNextStep()
            }
            await uiDelegate?.update(state: state)
        }

        // Done!
    }
}

/// Describes an accessibility object
struct ActionableElementDescription {
    /// A UUID to uniquely identify the object
    var id: UUID
    /// The role of the object
    var role: String
    /// The given description of the object
    var givenDescription: String
    /// The actions that the object accepts
    var actions: [ActionDescription]

    /// Describes an accessibility action
    struct ActionDescription {
        /// The name of the action, prefixed with "AX"
        var actionName: String
        /// The description of the action
        var description: String
    }

    /// Describes itself in a bullet point form. If the given description or actions are empty, this returns nil.
    var bulletPointDescription: String? {
        guard !givenDescription.isEmpty, !actions.isEmpty else { return nil }

        let desc = role + ": " + givenDescription + ": " + id.uuidString

        return String.build {
            " - " + desc

            for action in actions where action.actionName != "AXCancel" {
                "    - " + action.actionName + (
                    action.description.isEmpty
                    ? ""
                    : ": " + action.description
                )
            }
        }
    }
}

/// Provides accessibility information to an ``LLMManager``.
protocol AccessibilityItemProvider: AnyObject {
    /// Requests the provider to update its catalog of accessibility objects
    func updateAccessibilityObjects() async throws

    /// Requests the provider to provide the name of the current app. Nil if no app is focused.
    func getCurrentAppName() -> String?
    /// Requests the provider to provide a description of the currently focused element. Nil if no
    /// element is focused.
    func getFocusedElementDescription() -> String?

    /// Requests the provider to generate descriptions for accessibility objects and return them.
    /// Note that it should RANDOMLY generate `id`s for each element, and results for this
    /// function should NEVER be cached by the provider. IDs provided by this function will be
    /// referenced in calls to ``execute(action:onElementID:)``
    ///
    /// This should NOT return menu bar events.
    func generateElementDescriptions() async throws -> [ActionableElementDescription]
    /// Requests the provider to execute an action on an element with a given ID. This will always
    /// be called AFTER a call to ``generateElementDescriptions()``, but the ID is not
    /// guarenteed to exist.
    func execute(action: String, onElementID elementID: UUID) async throws
}

/// Provides a UI to the ``LLMManager``.
///
/// Note that the `LLMManager` only informs the display delegate about changes in the LLM
/// communication state. The ``AccessibilityItemProvider`` is responsible for updating
/// the UI directly about actionable elements.
protocol LLMDisplayDelegate: AnyObject {
    /// Shows the display UI
    func show() async
    /// Hides the display UI
    func hide() async
    /// Updates the display UI with a new state
    func update(state: LLMState) async
}
