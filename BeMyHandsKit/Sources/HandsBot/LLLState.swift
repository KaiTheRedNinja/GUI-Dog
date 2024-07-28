//
//  LLMCommunication.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 16/7/24.
//

import Element

/// Represents the data of an LLM communication
public struct LLMState: Equatable {
    /// The goal
    public var goal: String
    /// The steps to achieve the goal, or [] if ``commState`` is `.loading`
    public var steps: [LLMStep]
    /// The current step. Nil if `steps` is empty
    public var currentStepIndex: Int!

    /// Creates an LLM state
    public init(goal: String = "", steps: [LLMStep] = [], currentStepIndex: Int! = nil) {
        self.goal = goal
        self.steps = steps
        self.currentStepIndex = currentStepIndex
    }

    /// Computed property for the current step, gettable and settable
    public var currentStep: LLMStep {
        get {
            steps[currentStepIndex]
        }
        set {
            steps[currentStepIndex] = newValue
        }
    }

    /// The overall state, a computed summary of the steps' state
    public var overallState: LLMOverallState {
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

    /// The default LLM state
    public static var zero: LLMState { LLMState() }
}

/// A single step
public struct LLMStep: Equatable {
    /// The name of the step
    public var step: String
    /// The state of the step's completion
    public var state: LLMStepState

    /// Creates an LLMStep
    public init(step: String, state: LLMStepState) {
        self.step = step
        self.state = state
    }
}

public enum LLMStepState: Equatable {
    /// The step has not been reached yet
    case notReached
    /// The step is being worked on
    case working(ActionStepContext)
    /// The step completed without detected errors
    case complete
    /// The step completed with detected errors
    case error(LLMCommunicationError)
}

public enum LLMOverallState: Equatable {
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
public enum LLMCommunicationError: Error, Equatable {
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
    /// Element error
    case element(ElementError)
    /// Unknown error
    case unknown(any Error)

    /// Description of this error
    public var description: String {
        switch self {
        case .accessSnapshotNotFound: "The interactable UI elements are not available"
        case .textNotProvided: "The LLM did not respond with text when it was expected to"
        case .emptyResponse: "The LLM responded with an empty response"
        case .insufficientInformation: "The UI elements are not sufficient to achieve the goal"
        case .invalidFunctionCall: "The LLM responded with an invalid function call"
        case .actionFormatInvalid: "The LLM responded with an invalid action on an element"
        case .elementNotFound: "The LLM responded with a nonexistent element"
        case .actionNotFound: "The LLM responded with an action that the specified element does not support"
        case .element(let error): "Element error: \(error)"
        case .unknown(let error): "Unknown error: \(error)"
        }
    }

    public static func == (lhs: LLMCommunicationError, rhs: LLMCommunicationError) -> Bool {
        lhs.description == rhs.description
    }

    public init(_ baseError: any Error) {
        if let baseError = baseError as? LLMCommunicationError {
            self = baseError
        } else if let baseError = baseError as? ElementError {
            self = .element(baseError)
        } else {
            self = .unknown(baseError)
        }
    }
}

/// A structure that holds the context of a single "step" in Phase 2
public struct ActionStepContext: Hashable {
    /// The past actions done in this step. Nil if this is the first sub-step.
    public var pastActions: [String]?

    /// Creates an ActionStepContext
    public init(pastActions: [String]? = nil) {
        self.pastActions = pastActions
    }
}
