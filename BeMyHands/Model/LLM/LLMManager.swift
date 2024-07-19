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
    var accessibilityItemProvider: AccessibilityItemProvider!

    /// The UI delegate, which is informed of when the UI should update to reflect the manager's
    /// internal state. Optional.
    var uiDelegate: LLMDisplayDelegate?

    /// The current state
    private(set) var state: LLMState = .init(goal: "No Goal", steps: [])

    /// Creates a blank `LLMManager`
    init(
        accessibilityItemProvider: AccessibilityItemProvider! = nil,
        uiDelegate: LLMDisplayDelegate? = nil
    ) {
        self.accessibilityItemProvider = accessibilityItemProvider
        self.uiDelegate = uiDelegate
    }

    /// Sets `state` to `.step`, starting at step zero for steps. Should only be called ONCE, and will
    /// fatal error if called multiple times on the same instance.
    func setup(withGoal goal: String, steps: [String]) {
        assert(state.steps.isEmpty, "Steps must not have existed during setup")
        state = .init(
            goal: goal,
            steps: steps.map { .init(step: $0, state: .notReached) }
        )
        /// Switches to the first step
        updateStateToNextStep()
    }

    /// Switches to the next step in the state.
    ///
    /// This is called by ``setup(withGoal:steps:)`` to switch to the first step.
    internal func updateStateToNextStep() {
        if (state.currentStepIndex ?? -1) >= 0 { // complete the current step
            self.state.currentStep.state = .complete
        }
        // increase step index
        self.state.currentStepIndex = (state.currentStepIndex ?? -1) + 1
        // prepare new step, if exists
        if state.currentStepIndex < state.steps.count {
            self.state.currentStep.state = .working(.init(pastActions: []))
        }
    }

    /// Updates the state's current step to a new context
    internal func updateState(toStep newStepContext: ActionStepContext) {
        self.state.currentStep.state = .working(newStepContext)
    }

    /// Updates the state's current step to an error. Note that this will end communication.
    internal func updateState(toError error: LLMCommunicationError) {
        if (state.currentStepIndex ?? -1) >= 0 {
            self.state.currentStep.state = .error(error)
        } else {
            self.state.steps = [.init(step: "Error obtaining steps", state: .error(error))]
        }
    }

    /// Executes an action on an element with a certain description. Handles data checks to make sure that the element
    /// exists and that the action is valid.
    internal func execute(action: String, onElementID elementID: String) async throws {
        print("Executing [\(action)] on element with description [\(elementID)]")

        guard action.hasPrefix("AX") && !action.contains(" ") else {
            throw LLMCommunicationError.actionFormatInvalid
        }

        guard let elementID = UUID(uuidString: elementID) else {
            throw LLMCommunicationError.elementNotFound
        }

        try await accessibilityItemProvider.execute(action: action, onElementID: elementID)
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
        var action: String
    }
}

/// Provides accessibility information to an ``LLMManager``.
protocol AccessibilityItemProvider: AnyObject {
    /// Requests the provider to update its catalog of accessibility objects
    func updateAccessibilityObjects() async throws

    /// Requests the provider to provide the name of the current app. Nil if no app is focused.
    func getCurrentAppName() async -> String?
    /// Requests the provider to provide a description of the currently focused element. Nil if no
    /// element is focused.
    func getFocusedElementDescription() async -> String?

    /// Requests the provider to generate descriptions for accessibility objects and return them.
    /// Note that it should RANDOMLY generate `id`s for each element, and results for this
    /// function should NEVER be cached by the provider.
    func generateElementDescriptions() async throws -> [ActionableElementDescription]
    /// Requests the provider to execute an action on an element with a given ID
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
