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
///
/// The lifecycle goes like this:
/// 1. Create the ``LLMCommunication`` instance
/// 2. Call ``setup(withGoal:steps:)`` with the goal and steps.
/// 3. Do the following:
///     - Call ``updateCurrentElements(to:)`` when an element map is created
///     - Call ``execute(action:onElementWithDescription:)`` to execute an action, from the LLM's instruction
///     - If the call throws an error, call ``updateState(toError:)``
///     - If the call succeeded and the step is not complete, call ``updateState(toStep:)``
///     - Else, call ``updateStateToNextStep()`` to go to the next step.
/// 4. When ``updateStateToNextStep()`` is called on the last step, or ``updateState(toError:)`` is 
/// called on any step, the instance will enter  its "final stage" where further calls will be rejected. At this point,
/// it should be used for information displaying ONLY. Create a new instance for new communications.
class LLMCommunication {
    /// The current map of elements
    private(set) var elementMap: [String: ActionableElement]

    /// The current state
    private(set) var state: LLMState = .init(goal: "No Goal", steps: [])

    init() {
        self.elementMap = [:]
        self.state = .init(goal: "No Goal", steps: [])
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
    func updateStateToNextStep() {
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
    func updateState(toStep newStepContext: ActionStepContext) {
        self.state.currentStep.state = .working(newStepContext)
    }

    /// Updates the state's current step to an error. Note that this will end communication.
    func updateState(toError error: LLMCommunicationError) {
        self.state.currentStep.state = .error(error)
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
    var steps: [LLMStep]
    /// The current step. Nil if `steps` is empty
    var currentStepIndex: Int!

    /// Computed property for the current step, gettable and settable
    var currentStep: LLMStep {
        get {
            steps[currentStepIndex]
        }
        set {
            steps[currentStepIndex] = newValue
        }
    }

    /// The overall state, a computed summary of the steps' state
    var overallState: LLMOverallState {
        if steps.isEmpty { return .stepsNotLoaded }
        for step in steps {
            switch step.state {
            case .notReached, .working: // if a step has not been reached or is in progress, we're working.
                return .working
            case .error(let lLMCommunicationError): // if a step has failed, the state is error
                return .error(lLMCommunicationError)
            case .complete: break // if its complete, ignore it.
            }
        }

        // we went through all steps without finding an incomplete or failed step. That
        // means that steps have completed.
        return .complete
    }
}

struct LLMStep: Equatable {
    /// The name of the step
    var step: String
    /// The state of the step's completion
    var state: LLMStepState
}

enum LLMStepState: Equatable {
    /// The step has not been reached yet
    case notReached
    /// The step is being worked on
    case working(ActionStepContext)
    /// The step completed without detected errors
    case complete
    /// The step completed with detected errors
    case error(LLMCommunicationError)
}

enum LLMOverallState: Equatable {
    /// The steps have not been loaded
    case stepsNotLoaded
    /// The steps have been loaded and are being executed
    case working
    /// All steps have been completed without detected errors
    case complete
    /// Errors were detected during step execution
    case error(LLMCommunicationError)
}

/// An error in LLM communication
enum LLMCommunicationError: Error, Equatable {
    // Missing Info
    /// The accessibility snapshot does not exist
    case accessSnapshotNotFound
    /// The LLM did not supply text when text was requested
    case textNotProvided
    /// The LLM gave an empty response
    case emptyResponse

    // Phase One
    /// The LLM responded with "insufficient information"
    case insufficientInformation

    // Phase Two
    /// The LLM responded with an invalid function call
    case invalidFunctionCall
    /// The action is not formatted properly
    case actionFormatInvalid
    /// Element was not found in the ``LLMCommunication`` instance
    case elementNotFound
    /// Action is not a valid action on the `Element` instance
    case actionNotFound

    // Other
    /// Unknown error
    case unknown(any Error)

    /// Description of this error
    var description: String {
        switch self {
        case .accessSnapshotNotFound: "The interactable UI elements are not available"
        case .textNotProvided: "The LLM did not respond with text when it was expected to"
        case .emptyResponse: "The LLM responded with an empty response"
        case .insufficientInformation: "The UI elements are not sufficient to achieve the goal"
        case .invalidFunctionCall: "The LLM responded with an invalid function call"
        case .actionFormatInvalid: "The LLM responded with an invalid action on an element"
        case .elementNotFound: "The LLM responded with a nonexistent element"
        case .actionNotFound: "The LLM responded with an action that the specified element does not support"
        case .unknown(let error): "Unknown error: \(error)"
        }
    }

    static func == (lhs: LLMCommunicationError, rhs: LLMCommunicationError) -> Bool {
        lhs.description == rhs.description
    }

    init(_ baseError: any Error) {
        if let baseError = baseError as? LLMCommunicationError {
            self = baseError
        } else {
            self = .unknown(baseError)
        }
    }
}

/// A structure that holds the context of a single "step" in Phase 2
struct ActionStepContext: Hashable {
    /// The past actions done in this step. Nil if this is the first sub-step.
    var pastActions: [String]?
}
