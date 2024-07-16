//
//  PhaseTwo.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 16/7/24.
//

import Foundation
import GoogleGenerativeAI

extension AccessManager {
    func executeStep(context: ActionStepContext) async throws -> ActionStepContext? {
        // 1. Gather context
        guard let (description, elementMap) = try await prepareInteractableDescriptions() else {
            return nil
        }

        // Update the elements in the communication instance
        communication?.updateCurrentElements(to: elementMap)

        // 2. Prepare the prompt
        let prompt = String.build {
            """
You are my hands. I want to \(context.goal). You will be given the following:
- a goal
- a list of steps to achieve the goal that have already been completed, if any
- the step that I want you to execute
- actions to achieve said step that have already been executed
- steps that are yet to be done, if any

You will also be given some context, namely:
- The focused app
- The focused element
- Actioanble elements, in the form of actionable items (eg. buttons) on the screen
- Menu bar items

Actionable and menu bar items are in the format of:
 - [description]
    - [action name]: [action description]

When you call the function to execute an action on the element, refer to the element by \
its `description` and the action by its `action name`. Call the function exactly ONCE.

If the step has been completed after these actions, put `true` in the function \
call's isComplete parameter, else put `false`
"""
            "Goal: \(context.goal)"
            ""

            if context.currentStep > 0 {
                "Completed steps:"
                for step in context.allSteps[0..<context.currentStep] {
                    "   " + step
                }
                ""
            }

            "Current step: " + context.allSteps[context.currentStep]
            ""

            if let actions = context.pastActions {
                "Actions taken to achieve the step:"
                for action in actions {
                    " - " + action
                }
                ""
            }

            if context.currentStep < context.allSteps.count-1 {
                "Steps to do in the future:"
                for step in context.allSteps[(context.currentStep+1)...] {
                    "   " + step
                }
            } else {
                "This is the last step"
            }
            ""

            description
        }

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
                ),
                "isComplete": Schema(
                    type: .boolean,
                    description: "If the current step can be considered as complete after this action is executed"
                )
            ],
            requiredParameters: ["brightness", "colorTemperature"]
        )

        // 3. Request the AI
        let model = GenerativeModel(
            name: "gemini-1.5-flash",
            apiKey: Secrets.geminiKey,
            // Specify the function declaration.
            tools: [Tool(functionDeclarations: [executeActionDecl])]
        )

        let response = try await model.generateContent(prompt)

        // validate the function call. TODO: allow multiple function calls
        guard let functionCall = response.functionCalls.first, functionCall.name == "executeAction" else {
            print("Model did not respond with a valid function call.")
            return nil
        }

        // 4. Execute the actions

        // validate that the parameters are present
        guard
            case let .string(itemDesc) = functionCall.args["itemDescription"],
            case let .string(actionName) = functionCall.args["actionName"],
            case let .bool(isComplete) = functionCall.args["isComplete"]
        else {
            print("Model responded with a missing parameter.")
            return nil
        }

        try await communication?.execute(action: actionName, onElementWithDescription: itemDesc)

        // 5. If the AI says that the step has not been completed, then recurse
        if isComplete {
            return ActionStepContext(
                goal: context.goal,
                allSteps: context.allSteps,
                currentStep: context.currentStep+1
            )
        } else {
            return ActionStepContext(
                goal: context.goal,
                allSteps: context.allSteps,
                currentStep: context.currentStep,
                pastActions: (context.pastActions ?? []) + ["\(itemDesc): \(actionName)"]
            )
        }
    }
}
