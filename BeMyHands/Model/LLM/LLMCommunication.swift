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

    /// The current state
    private(set) var state: LLMState = .init(goal: "No Goal", steps: [], commState: .loading)

    init() {
        self.elementMap = [:]
        self.state = .init(goal: "No Goal", steps: [], commState: .loading)
    }

    /// Sets `state` to `.step`, starting at step zero for steps. Should only be called ONCE, and will
    /// fatal error if called multiple times on the same instance.
    func setup(withGoal goal: String, steps: [String]) {
        assert(state.commState == .loading, "Steps must not have existed during setup")
        state = .init(goal: goal, steps: steps, commState: .step(.init(currentStep: 0)))
    }

    /// Updates the state to another step
    func updateState(toStep newStepContext: ActionStepContext) {
        self.state.commState = .step(newStepContext)
    }

    /// Updates the state to a success
    func updateStateToComplete() {
        self.state.commState = .complete
    }

    /// Updates the state to an error
    func updateState(toError error: LLMCommunicationError) {
        self.state.commState = .error(error)
    }

    /// Updates the elementMap
    func updateCurrentElements(to elementMap: [String: ActionableElement]) {
        self.elementMap = elementMap
    }

    /// Executes an action on an element with a certain description. Handles data checks to make sure that the element
    /// exists and that the action is valid.
    func execute(action: String, onElementWithDescription elementDescription: String) async throws {
        print("Executing [\(action)] on element with description [\(elementDescription)]")

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

/// Represents the data of an LLM communication
struct LLMState: Equatable {
    /// The goal
    var goal: String
    /// The steps to achieve the goal, or [] if ``commState`` is `.loading`
    var steps: [String]
    /// The state of communication, with additional data if relevant
    var commState: LLMCommunicationState
}

/// Represents the state that a communication is currently in
enum LLMCommunicationState: Equatable {
    /// Steps not loaded yet
    case loading
    /// Steps loaded, executing them
    case step(ActionStepContext)
    /// Steps complete without known errors
    case complete
    /// Steps complete with known error
    case error(LLMCommunicationError)
}

/// An error in LLM communication
enum LLMCommunicationError: Error, Equatable {
    /// The action is not formatted properly
    case actionFormatInvalid
    /// Element was not found in the ``LLMCommunication`` instance
    case elementNotFound
    /// Action is not a valid action on the `Element` instance
    case actionNotFound
    /// Unknown error
    case unknown(any Error)

    static func == (lhs: LLMCommunicationError, rhs: LLMCommunicationError) -> Bool {
        switch lhs {
        case .actionFormatInvalid:
            return rhs == .actionFormatInvalid
        case .elementNotFound:
            return rhs == .elementNotFound
        case .actionNotFound:
            return rhs == .actionNotFound
        case .unknown(let errorLHS):
            switch rhs {
            case .unknown(let errorRHS):
                return errorLHS.localizedDescription == errorRHS.localizedDescription
            default: return false
            }
        }
    }
}

/// A structure that holds the context of a single "step" in Phase 2
struct ActionStepContext: Hashable {
    /// The current step
    var currentStep: Int
    /// The past actions done in this step. Nil if this is the first sub-step.
    var pastActions: [String]?
}
