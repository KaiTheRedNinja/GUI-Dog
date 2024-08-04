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
    /// Determines a function to call to work towards a goal
    /// - Parameters:
    ///   - state: The LLM state
    func determineFunction(
        state: LLMState
    ) async throws -> StepResult {
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

To work towards this goal, you have the following tools:

"""

            for stepCapabilityProvider in self.stepCapabilityProviders {
                " - "
                    + stepCapabilityProvider.name
                (
                    stepCapabilityProvider.description + ". "
                    + stepCapabilityProvider.instructions
                )
                .tab(count: 4)
                ""
            }

            """

Respond with one of the following:
- The name of ONLY ONE of the tools: \(stepCapabilityProviders.map { $0.name }), followed by a colon, and \
a HUMAN READABLE description of what you intend to do with the tool. For example, "ActionName: Readable \
description about what you want to use the tool for". Do not include any UUIDs, and use actions' descriptions
instead of names.
- If the goal has already been satisfied, respond with "DONE", in text. You may determine this from the context, or \
from the list of past steps.
- If the step requires an action that none of the tools provide, such as dragging, typing, or copy-paste, respond with
"NO TOOL", in text, followed by a colon, and a HUMAN READABLE explanation of why the goal cannot be achieved from the \
current state.

If you respond with the name of a tool, remember to USE THE TOOL in a FUNCTION CALL, following its instructions.

Note that your action does not need to achieve the goal, it just needs to get closer. If the action is complete, \
respond with "DONE".

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

        let result = try await llmProvider?.generateResponse(
            prompt: prompt,
            functions: stepCapabilityProviders
                .map {
                    $0.functionDeclaration
                }
        )

        guard let result, let text = result.text else {
            throw LLMCommunicationError.emptyResponse
        }

        guard !text.contains("DONE") else {
            return .goalFinished
        }

        // get the text components
        let components = text.components(separatedBy: ":")
        guard components.count >= 2 else {
            throw LLMCommunicationError.emptyResponse
        }

        let reason = components.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.contains("NO TOOL") else {
            throw LLMCommunicationError.goalImpossible(reason: reason)
        }

        // at this stage, it means that the AI is trying to call a function
        let functionCalls = result.functionCalls
        guard let funcCall = functionCalls.first else {
            throw LLMCommunicationError.emptyResponse
        }

        return .executeStep(call: funcCall, reason: reason)
    }

    /// Executes the given function
    func executeFunction(
        state: LLMState,
        function: LLMFuncCall
    ) async throws {
        let name = function.name
        guard let provider = stepCapabilityProviders.first(where: { $0.name == name }) else {
            throw LLMCommunicationError.invalidFunctionCall
        }
        try await provider.execute(function: function)
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

enum StepResult {
    case goalFinished
    case executeStep(call: LLMFuncCall, reason: String)
}
