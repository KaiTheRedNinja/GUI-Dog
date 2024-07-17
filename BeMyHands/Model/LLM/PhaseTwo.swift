//
//  PhaseTwo.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 16/7/24.
//

import Foundation
import GoogleGenerativeAI

extension AccessManager {
    func executeStep(goal: String, steps: [String], context: ActionStepContext) async throws -> ActionStepContext? {
        // 1. Gather context
        guard let (description, elementMap) = try await prepareInteractableDescriptions() else {
            return nil
        }

        // Update the elements in the communication instance
        communication?.updateCurrentElements(to: elementMap)

        // 2. Prepare the prompt
        let prompt = String.build {
            """
You are my hands. I want to \(goal). You will be given the following:
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
exactly ONCE.
"""
            "Goal: \(goal)"
            ""

            if context.currentStep > 0 {
                "Completed steps:"
                for step in steps[0..<context.currentStep] {
                    "   " + step
                }
                ""
            }

            "Current step: " + steps[context.currentStep]
            ""

            if let actions = context.pastActions {
                "Actions taken to achieve the step:"
                for action in actions {
                    " - " + action
                }
                ""
            }

            /*
            if context.currentStep < context.allSteps.count-1 {
                "Steps to do in the future:"
                for step in context.allSteps[(context.currentStep+1)...] {
                    "   " + step
                }
            } else {
                "This is the last step"
            }
            ""
             */

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
                )
            ],
            requiredParameters: ["itemDescription", "actionName"]
        )

        // 3. Request the AI
        let model = GenerativeModel(
            name: "gemini-1.5-flash",
            apiKey: Secrets.geminiKey,
            // Specify the function declaration.
            tools: [Tool(functionDeclarations: [executeActionDecl])]
        )

        print("Prompt to step \(context.currentStep): \(prompt)")

        let response = try await model.generateContent(prompt)

        print("Step response: \(response)")

        // validate the function call. TODO: allow multiple function calls
        guard let functionCall = response.functionCalls.first, functionCall.name == "executeAction" else {
            print("Model did not respond with a valid function call.")
            return nil
        }

        // 4. Execute the actions

        // validate that the parameters are present
        guard
            case let .string(itemDesc) = functionCall.args["itemDescription"],
            let lastComponent = itemDesc.split(separator: " ").last,
            UUID(uuidString: String(lastComponent)) != nil,
            case let .string(actionName) = functionCall.args["actionName"]
        else {
            print("Model responded with a missing parameter.")
            return nil
        }

        try await communication?.execute(action: actionName, onElementWithDescription: String(lastComponent))

        // 5. If the AI says that the step has not been completed, then recurse
        // TODO: get recursing working again. I currently assume every action completes its step.
        return ActionStepContext(
            currentStep: context.currentStep+1
        )
    }
}
