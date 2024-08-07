//
//  LLMCommunication.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 16/7/24.
//

/// Represents the data of an LLM communication
public struct LLMState: Equatable {
    /// The goal
    public var goal: String
    /// The steps that the LLM has and is taking to achieve the goal. The last step is the current step.
    public var steps: [LLMStep]
    /// The state of the LLM
    public var overallState: LLMOverallState = .checkingFeasibility

    /// Creates an LLM state
    public init(
        goal: String = "",
        steps: [LLMStep] = [],
        overallState: LLMOverallState = .checkingFeasibility
    ) {
        self.goal = goal
        self.steps = steps
    }

    /// The default LLM state
    public static var zero: LLMState { LLMState() }
}

/// A single step
public struct LLMStep: Equatable {
    /// The name of the step
    public var step: String

    /// Creates an LLMStep
    public init(step: String) {
        self.step = step
    }
}

public enum LLMOverallState: Equatable {
    /// Checking the feasibility of the goal
    case checkingFeasibility
    /// Working on achieving the goal
    case working
    /// All steps have been completed without detected errors
    case complete
    /// The execution was cancelled
    case cancelled
    /// Errors were detected during step execution
    case error(LLMCommunicationError)
}

/// An error in LLM communication
public enum LLMCommunicationError: Error, Equatable {
    // Missing Info
    /// The LLM did not supply text when text was requested
    case textNotProvided
    /// The LLM gave an empty response
    case emptyResponse

    // Phase One
    /// The LLM determined that the goal is impossible
    case goalImpossible(reason: String)

    // Phase Two
    /// The LLM responded with an invalid function call
    case invalidFunctionCall

    // Other
    /// Other error
    case other(any LLMOtherError)
    /// Unknown error
    case unknown(any Error)

    /// Description of this error
    public var description: String {
        switch self {
        case .textNotProvided: "The LLM did not respond with text when it was expected to"
        case .emptyResponse: "The LLM did not respond. Try again in a few seconds."
        case .goalImpossible(let reason): "The goal cannot be achieved because \(reason)"
        case .invalidFunctionCall: "The LLM tried to do something that GUI Dog does not support"
        case .other(let error): error.description
        case .unknown(let error): "Something else went wrong: \(error)"
        }
    }

    public static func == (lhs: LLMCommunicationError, rhs: LLMCommunicationError) -> Bool {
        lhs.description == rhs.description
    }

    public init(_ baseError: any Error) {
        if let baseError = baseError as? LLMCommunicationError {
            self = baseError
        } else if let baseError = baseError as? LLMOtherError {
            self = .other(baseError)
        } else {
            self = .unknown(baseError)
        }
    }
}

public protocol LLMOtherError: Error {
    var description: String { get }
}
