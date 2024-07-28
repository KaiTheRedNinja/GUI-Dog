//
//  HandsBot+PhaseTwo.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 19/7/24.
//

import Foundation
import OSLog

private let logger = Logger(subsystem: #fileID, category: "HandsBot")

extension HandsBot {
    /// Chooses a provider
    /// - Parameters:
    ///   - state: The LLM state
    ///   - context: The LLM context
    /// - Returns: The provider and its context, to be reused if it exists
    func chooseProvider(
        state: LLMState
    ) async throws -> ProviderChoice {
        // Gather context
        var contexts: [String] = []
        var contextMap: [String: String] = [:]
        for stepCapabilityProvider in self.stepCapabilityProviders {
            // no need to update the context here, it was updated previously.
            let itemContext = try await stepCapabilityProvider.getContext()
            if let itemContext {
                contexts.append(itemContext)
                contextMap[stepCapabilityProvider.name] = itemContext
            }
        }

        // Prepare the prompt
        let prompt = String.build {
            stepStateDescription(state: state)

            for itemContext in contexts {
                itemContext
                "\n"
            }

            """

To work towards this goal, select one of the following tools:
"""

            for stepCapabilityProvider in self.stepCapabilityProviders {
                // TODO: use UUIDs instead of names for greater resillience
                " - " + stepCapabilityProvider.name + ": " + stepCapabilityProvider.description
            }

            """

Respond in text with one of the following:
- The name of ONLY ONE of the tools: \(stepCapabilityProviders.map { $0.name }), followed by a colon, and \
a human-readable description of what you intend to do with the tool. For example, "ActionName: Readable \
description about what you want to use the tool for".
- "NO TOOL" if the step requires an action that none of the tools provide.
- "DONE" if the goal has already been satisfied. You may determine this from the context, or from the \
list of past steps.

Note that your action does not need to achieve the goal, it just needs to get closer.

"""

            // must be >= 1 steps, because `chooseProvider` may be called with 0 steps
            if state.steps.count >= 1 {
                "You have already done the following previous actions. Do NOT repeat them:"
                for action in state.steps {
                    " - " + action.step
                }
            } else {
                "No previous actions have been executed."
            }
        }

        let result = try await llmProvider?.generateResponse(prompt: prompt, functions: nil)

        guard let result, let text = result.text else {
            throw LLMCommunicationError.emptyResponse
        }

        guard !text.contains("NO TOOL") else {
            throw LLMCommunicationError.goalImpossible(reason: "No Tool")
        }

        guard !text.contains("DONE") else {
            return .init(providerName: "DONE", intention: "")
        }

        let components = text.components(separatedBy: ":")
        guard components.count >= 2 else {
            throw LLMCommunicationError.emptyResponse
        }

        let provider = components.first!.trimmingCharacters(in: .whitespacesAndNewlines)
        let reason = components.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespacesAndNewlines)

        guard let provider = stepCapabilityProviders.first(where: { provider.contains($0.name) }) else {
            throw LLMCommunicationError.invalidFunctionCall
        }

        return .init(
            providerName: provider.name,
            intention: reason,
            context: contextMap[provider.name]
        )
    }

    func executeStep(
        state: LLMState,
        providerChoice: ProviderChoice
    ) async throws {
        guard let provider = stepCapabilityProviders.first(where: { $0.name == providerChoice.providerName }) else {
            throw LLMCommunicationError.invalidFunctionCall
        }

        // Prepare the prompt
        let prompt = String.build {
            stepStateDescription(state: state)

            if let relevantContext = providerChoice.context {
                relevantContext
            }

            """
            To achieve this goal, follow these instructions and call the \(provider.name) tool function \
            to \(providerChoice.intention)
            """

            provider.instructions

            """
            Call the function exactly ONCE. Respond with a FUNCTION CALL, NOT a code block.

            If you cannot use the tool to \(providerChoice.intention), reply with "CANNOT EXECUTE".
            """

            // must have more than one step, because `executeStep` will always be called with one step
            // (the current step)
            if state.steps.count > 1 {
                "You have already done the following previous actions:"
                for action in state.steps.dropLast() {
                    " - " + action.step
                }
            } else {
                "No previous actions have been executed."
            }
        }

        let result = try await llmProvider?.generateResponse(prompt: prompt, functions: [
            provider.functionDeclaration
        ])

        guard let result else {
            throw LLMCommunicationError.invalidFunctionCall
        }

        guard !(result.text?.contains("CANNOT EXECUTE") ?? false) else {
            // TODO: get a reason
            throw LLMCommunicationError.goalImpossible(reason: "NOT YET DETERMINED")
        }

        guard let functionCall = result.functionCalls.first, functionCall.name == provider.name else {
            provider.functionFailed()
            throw LLMCommunicationError.invalidFunctionCall
        }

        try await provider.execute(function: functionCall)
    }

    private func stepStateDescription(state: LLMState) -> String {
        String.build {
            """
            You are my hands. I want to \(state.goal). You will be given the following:
            - a goal
            - actions to achieve that goal that have already been executed, if any

            """

            "Goal: \(state.goal)"
            ""
        }
    }
}

struct ProviderChoice {
    var providerName: String
    var intention: String
    var context: String?
}
