//
//  LLMManager+PhaseTwo.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 19/7/24.
//

import Foundation
import GoogleGenerativeAI

extension LLMManager {
    func executeStep(state: LLMState, context: ActionStepContext) async throws -> StepExecutionStatus {
        let prompt = try await preparePrompt(state: state, context: context)
        let model = prepareModel()

        print("Prompt to step \(state.currentStepIndex!): \(prompt)")
        let response = try await model.generateContent(prompt)
        print("Step response: \(response)")

        // validate the function call. TODO: allow multiple function calls
        guard let functionCall = response.functionCalls.first, functionCall.name == "executeAction" else {
            print("Model did not respond with a valid function call.")
            throw LLMCommunicationError.invalidFunctionCall
        }

        // Execute the actions

        // validate that the parameters are present
        guard
            case let .string(itemDesc) = functionCall.args["itemDescription"],
            let lastComponent = itemDesc.split(separator: " ").last,
            UUID(uuidString: String(lastComponent)) != nil,
            case let .string(actionName) = functionCall.args["actionName"]
        else {
            print("Model responded with a missing parameter.")
            throw LLMCommunicationError.invalidFunctionCall
        }

        try await execute(action: actionName, onElementID: String(lastComponent))

        // If the AI says that the step has not been completed, then recurse
        // TODO: get recursing working again. I currently assume every action completes its step.
        return .complete
    }

    private func preparePrompt(state: LLMState, context: ActionStepContext) async throws -> String {
        // Gather context
        let appName = await accessibilityItemProvider.getCurrentAppName()
        let focusedDescription = await accessibilityItemProvider.getFocusedElementDescription()
        let descriptions = try await accessibilityItemProvider.generateElementDescriptions()

        // Prepare the prompt
        let prompt = String.build {
            """
You are my hands. I want to \(state.goal). You will be given the following:
- a goal
- a list of steps to achieve the goal that have already been completed, if any
- the step that I want you to execute
- actions to achieve said step that have already been executed

You will also be given some context, namely:
- The focused app
- The focused element
- Actioanble elements, in the form of actionable items (eg. buttons) on the screen
- Menu bar items

Actionable and menu bar items are in the format of:
 - [description]: [UUID]
    - [action name]: [action description]

Use the `executeAction` function call. When you call the function to execute an action \
on the element, refer to the element by its `description` AND `UUID` EXACTLY as it is \
given in [description]: [UUID] and the action by its `action name`. Call the function \
exactly ONCE. Respond with a FUNCTION CALL, NOT a code block.
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

            if let actions = context.pastActions {
                "Actions taken to achieve the step:"
                for action in actions {
                    " - " + action
                }
                ""
            }

            if let appName {
                "The focused app is \(appName)"
            } else {
                "There is no focused app"
            }

            "\n"

            if let focusedDescription {
                "The focused element is \(focusedDescription)"
            } else {
                "There is no focused element"
            }

            "\n"

            "The actionable elements are:"
            for description in descriptions {
                if let description = description.bulletPointDescription {
                    description
                }
            }
        }

        return prompt
    }

    private func prepareModel() -> GenerativeModel {
        // prepare the declaration
        let executeActionDecl = FunctionDeclaration(
            name: "executeAction",
            description: "Executes a single action, such as a press or open, on an actionable item",
            parameters: [
                "itemDescription": Schema(
                    type: .string,
                    description: "The given description of the item"
                ),
                "actionName": Schema(
                    type: .string,
                    description: "The given name of the action, usually prefixed with AX"
                )
            ],
            requiredParameters: ["itemDescription", "actionName"]
        )

        // 3. Request the AI
        let model = GenerativeModel(
            name: "gemini-1.5-flash",
            apiKey: Secrets.geminiKey,
            // Specify the function declaration.
            tools: [Tool(functionDeclarations: [executeActionDecl])],
            toolConfig: .init(
                functionCallingConfig: .init(
                    mode: .any,
                    allowedFunctionNames: ["executeAction"]
                )
            )
        )

        return model
    }
}
