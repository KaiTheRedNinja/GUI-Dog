//
//  HandsBot.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 19/7/24.
//

import Foundation
import Access
import GoogleGenerativeAI

/// A class that facilitates the conversation with an LLM. This manager should be RESET
/// for every conversation.
public class HandsBot {
    /// The discovery context providers
    public var discoveryContentProviders: [any DiscoveryContextProvider] = []

    /// The step capability providers. Note that their names MUST NOT be substrings of another name, or
    /// else it may cause issues with the LLM.
    public var stepCapabilityProviders: [any StepCapabilityProvider] = []

    /// The UI delegate, which is informed of when the UI should update to reflect the manager's
    /// internal state. Optional.
    public weak var uiDelegate: LLMDisplayDelegate?

    /// The API provider, which provides the API key
    public weak var apiKeyProvider: APIKeyProvider!

    /// The current state
    var state: LLMState = .zero

    /// Creates a blank ``HandsBot``
    public init() {}

    /// Requests actions from the Gemini API based on a request and the current `accessSnapshot`
    public func requestLLMAction(goal: String) async {
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

        // update the capability providers
        do {
            for stepCapabilityProvider in stepCapabilityProviders {
                try await stepCapabilityProvider.updateContext()
            }
        } catch {
            print("Could not update capabilities")
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

            // update the capability providers
            do {
                for stepCapabilityProvider in stepCapabilityProviders {
                    try await stepCapabilityProvider.updateContext()
                }
            } catch {
                print("Could not update capabilities")
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

/// Provides context to the LLM when deciding the steps to execute in phase one.
public protocol DiscoveryContextProvider {
    /// Called before ``getContext()`` to inform the provider to update the context
    func updateContext() async throws
    /// Get the context. Nil if context is unavailable.
    func getContext() async throws -> String?
}

/// Provides a capability to the LLM while executing a step.
///
/// The LLM can decide to use a capability when executing a step.
/// 1. ``name`` and ``description`` are retrieved for each capability and given to theLLM
/// 2. The LLM chooses a capability, or exits if none match the task
/// 3. ``instructions`` and ``getContext()`` are used to provide instructions to the LLM
/// for how to use the capability, and any context if the capability requires options.
public protocol StepCapabilityProvider {
    /// The name of the capability. Should be IDENTICAL to the ``functionDeclaration``'s `name`
    var name: String { get }
    /// A description of the capability. Should be a verb, eg. "Click on on-screen buttons"
    var description: String { get }
    /// The instructions for how to use the capability. Will be given verbatim to the LLM.
    var instructions: String { get }
    /// The function for the LLM to call to execute the step
    var functionDeclaration: FunctionDeclaration { get }

    /// Called before ``getContext()`` to inform the provider to update the context
    func updateContext() async throws
    /// The context for using the capability, such as the currently open app. Nil if context is not
    /// needed.
    func getContext() async throws -> String?
    /// Called whenever the LLM responds with a function declaration with the correct name. Note
    /// that this DOES NOT guarentee that the function call is actually correct; this function should
    /// validate parameters before execution.
    func execute(function: FunctionCall) async throws
    /// Called whenever the LLM responds but does not call the given function
    func functionFailed()
}

/// Provides the Gemini API key
public protocol APIKeyProvider: AnyObject {
    /// Provides the Gemini API key
    func getKey() -> String
}

/// Provides a UI to the ``HandsBot``.
///
/// Note that the `HandsBot` only informs the display delegate about changes in the LLM
/// communication state. The ``AccessibilityItemProvider`` is responsible for updating
/// the UI directly about actionable elements.
public protocol LLMDisplayDelegate: AnyObject {
    /// Shows the display UI
    func show() async
    /// Hides the display UI
    func hide() async
    /// Updates the display UI with a new state
    func update(state: LLMState) async
}
