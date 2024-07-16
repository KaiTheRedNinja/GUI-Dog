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

        // 2. Prepare the prompt
        let prompt = try String.build {
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
its `description` and the action by its `action name`.

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

        // 3. Request the AI
        print("Requesting ai: \(prompt)")
        // 4. Execute the actions
        // 5. If the AI says that the step has not been completed, then recurse

        fatalError("Not yet implemented")
    }
}
