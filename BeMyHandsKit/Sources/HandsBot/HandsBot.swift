//
//  HandsBot.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 19/7/24.
//

import Foundation
import Access
import OSLog

private let logger = Logger(subsystem: #fileID, category: "HandsBot")

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

    /// The LLM provider, which provides access to the chatbot
    public weak var llmProvider: LLMProvider?

    /// The current state
    var state: LLMState = .zero

    /// Creates a blank ``HandsBot``
    public init() {}

    /// Cancels an LLM request. Note that HandsBot _may_ continue to execute ``requestLLMAction(goal:)`` due to
    /// how memory retention works.
    ///
    /// This function simply cuts off its access to its providers and delegates, so when it tries to reach for one of
    /// them it will be denied, causing an error to be thrown. This error is then swallowed, as the ``uiDelegate``
    /// is no longer available.
    public func cancel() {
        state = .zero
        state.overallState = .cancelled
        discoveryContentProviders = []
        stepCapabilityProviders = []
        uiDelegate = nil
        llmProvider = nil
    }

    /// Requests actions from the Gemini API based on a request and the current `accessSnapshot`
    public func requestLLMAction(goal: String) async {
        guard state == .zero else {
            logger.info("Could not request LLM: LLM already running")
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
        if await updateCapabilityProviders() == false { return }

        // Phase 1: Determine if the goal is possible
        if await phaseOne(goal: goal) == false { return }

        // update the state
        await uiDelegate?.update(state: state)

        // Phase 2: Satisfy the steps one by one

        // note that this MAY result in infinite loops, if the AI doesn't ever say that
        // it is complete
        while state.overallState != .complete {
            // execute phase two
            if await phaseTwo() == false { return }

            // update the state
            await uiDelegate?.update(state: state)
        }

        // Done!
    }

    private func updateCapabilityProviders() async -> Bool {
        do {
            for stepCapabilityProvider in stepCapabilityProviders {
                try await stepCapabilityProvider.updateContext()
            }
            return true
        } catch {
            logger.error("Could not update capabilities")
            updateState(toError: .init(error))
            return false
        }
    }

    private func phaseOne(goal: String) async -> Bool {
        do {
            try await determineGoalFeasibility(goal: goal)
        } catch {
            updateState(toError: .init(error))
            return false
        }

        return true
    }

    private func phaseTwo() async -> Bool {
        // update the capability providers
        if await updateCapabilityProviders() == false { return false }

        do {
            let providerChoice = try await chooseProvider(state: state)

            if providerChoice.providerName == "DONE" {
                updateStateToComplete()
                return true
            }

            // update the state and ui
            addStep(providerChoice.intention)
            await uiDelegate?.update(state: state)

            try await executeStep(
                state: state,
                providerChoice: providerChoice
            )
        } catch {
            logger.error("Could not execute the step")
            updateState(toError: .init(error))
            return false
        }

        return true
    }
}
