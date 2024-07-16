//
//  LLMCommunication.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 16/7/24.
//

import Element

/// Holds and manages the data associated with the communication between BeMyHands and the LLM.
///
/// Acts as the interface for LLMs to take actions. Note that this manages data and the interface; it DOES NOT
/// manage the communication or parsing of LLM responses.
class LLMCommunication {
    /// The current map of elements
    private(set) var elementMap: [String: ActionableElement]

    /// The current step's context. Nil if no steps have been taken.
    private(set) var stepContext: ActionStepContext!

    init() {
        self.elementMap = [:]
        self.stepContext = nil
    }

    /// Creates a `stepContext` starting at step zero for steps. Should only be called ONCE, and will
    /// fatal error if called multiple times on the same instance.
    func setup(withGoal goal: String, steps: [String]) {
        assert(stepContext == nil, "Step context must not exist during setup stage")
        stepContext = .init(goal: goal, allSteps: steps, currentStep: 0)
    }

    /// Updates the step
    func updateStepContext(to newStepContext: ActionStepContext) {
        self.stepContext = newStepContext
    }

    /// Updates the elementMap
    func updateCurrentElements(to elementMap: [String: ActionableElement]) {
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

/// An error in LLM communication
enum LLMCommunicationError: Error {
    /// The action is not formatted properly
    case actionFormatInvalid

    /// Element was not found in the ``LLMCommunication`` instance
    case elementNotFound
    /// Action is not a valid action on the `Element` instance
    case actionNotFound
}

/// A structure that holds the context of a single "step" in Phase 2
struct ActionStepContext {
    /// The goal
    var goal: String
    /// The full list of steps
    var allSteps: [String]
    /// The current step
    var currentStep: Int
    /// The past actions done in this step. Nil if this is the first sub-step.
    var pastActions: [String]?
}
