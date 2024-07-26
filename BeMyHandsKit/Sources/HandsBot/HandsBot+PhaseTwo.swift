//
//  HandsBot+PhaseTwo.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 19/7/24.
//

import Foundation
import OSLog

private let logger = Logger(subsystem: #file, category: "HandsBot")

extension HandsBot {
    func executeStep(state: LLMState, context: ActionStepContext) async throws -> StepExecutionStatus {
        guard !stepCapabilityProviders.isEmpty else {
            fatalError("No step capability providers!")
        }

        // Allow the LLM to pick which provider to use
        let (provider, relevantContext) = try await chooseProvider(
            state: state,
            context: context
        )

        // Execute the step
        try await executeStep(
            withProvider: provider,
            state: state,
            context: context,
            relevantContext: relevantContext
        )

        // If the AI says that the step has not been completed, then recurse
        // TODO: get recursing working again. I currently assume every action completes its step.
        return .complete
    }

    /// Chooses a provider
    /// - Parameters:
    ///   - state: The LLM state
    ///   - context: The LLM context
    /// - Returns: The provider and its context, to be reused if it exists
    private func chooseProvider(
        state: LLMState,
        context: ActionStepContext
    ) async throws -> (any StepCapabilityProvider, String?) {
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
            stepStateDescription(state: state, context: context)

            for itemContext in contexts {
                itemContext
                "\n"
            }

            """

To achieve this goal, select one of the following tools:
"""

            for stepCapabilityProvider in self.stepCapabilityProviders {
                // TODO: use UUIDs instead of names for greater resillience
                " - " + stepCapabilityProvider.name + ": " + stepCapabilityProvider.description
            }

            """

Respond in text with the names of THE NAME OF ONLY ONE of the tools: \(stepCapabilityProviders.map { $0.name }), or \
"NO TOOL" if the step requires an action that none of the tools provide.
"""
        }

        logger.info("Choose prompt: \(prompt)")

        let result: LLMResponse
        result = try await llmProvider.generateResponse(prompt: prompt, functions: nil)

        guard let text = result.text else {
            throw LLMCommunicationError.emptyResponse
        }

        logger.info("Response: \(text)")

        guard !text.contains("NO TOOL") else {
            throw LLMCommunicationError.insufficientInformation
        }

        // TODO: use UUIDs instead of their names
        guard let provider = stepCapabilityProviders.first(where: { text.contains($0.name) }) else {
            throw LLMCommunicationError.invalidFunctionCall
        }

        return (provider, contextMap[provider.name])
    }

    private func executeStep(
        withProvider provider: any StepCapabilityProvider,
        state: LLMState,
        context: ActionStepContext,
        relevantContext: String?
    ) async throws {
        // Prepare the prompt
        let prompt = String.build {
            stepStateDescription(state: state, context: context)

            if let relevantContext {
                relevantContext
            }

            """
            To achieve this goal, follow these instructions and call the \(provider.name) tool function:
            """

            provider.instructions

            """
            Call the function exactly ONCE. Respond with a FUNCTION CALL, NOT a code block.
            """
        }

        logger.info("Result prompt: \(prompt)")

        let result = try await llmProvider.generateResponse(prompt: prompt, functions: [
            provider.functionDeclaration
        ])

        logger.info("Response: \(String(describing: result))")

        guard let functionCall = result.functionCalls.first, functionCall.name == provider.name else {
            provider.functionFailed()
            throw LLMCommunicationError.invalidFunctionCall
        }

        try await provider.execute(function: functionCall)
    }

    private func stepStateDescription(state: LLMState, context: ActionStepContext) -> String {
        String.build {
            """
            You are my hands. I want to \(state.goal). You will be given the following:
            - a goal
            - a list of steps to achieve the goal that have already been completed, if any
            - the step that I want you to execute
            - actions to achieve said step that have already been executed, if any

            """

            "Goal: \(state.goal)"
            ""

            if state.currentStepIndex > 0 {
                "Completed steps:"
                for step in state.steps[0..<state.currentStepIndex] {
                    "   " + step.step
                }
                ""
            }

            "Current step: " + state.currentStep.step
            ""

            if let actions = context.pastActions, !actions.isEmpty {
                "Actions taken to achieve the step:"
                for action in actions {
                    " - " + action
                }
                ""
            }
        }
    }
}

/// Represents the execution result of a step
enum StepExecutionStatus {
    /// The step is not complete, with a status
    case incomplete(ActionStepContext)
    /// The step has completed
    case complete
}
