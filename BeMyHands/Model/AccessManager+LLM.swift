//
//  AccessManager+LLM.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 15/7/24.
//

import Foundation
import Access
import Element
import HandsBot
import GoogleGenerativeAI
import OSLog

private let logger = Logger(subsystem: #fileID, category: "BeMyHands")

extension AccessManager: StepCapabilityProvider, DiscoveryContextProvider {
    var name: String {
        "executeAction"
    }

    var description: String {
        "Click or opens elements visible on screen"
    }

    var instructions: String {
        """
        Actionable items are in the format of:
        - [description]: [UUID]
            - [action name]: [action description]

        Use the `executeAction` function call. When you call the function to execute an action \
        on the element, refer to the element by its `description` AND `UUID` EXACTLY as it is \
        given in [description]: [UUID] and the action by its `action name`.
        """
    }

    var functionDeclaration: LLMFuncDecl {
        FunctionDeclaration(
            name: self.name,
            description: self.description,
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
    }

    func updateContext() async throws {
        logger.info("Updating context!")
        try await takeAccessSnapshot()
        await uiDelegate?.update(actionableElements: accessSnapshot?.actionableItems ?? [])
        logger.info("Context updated!")
    }

    @_implements(DiscoveryContextProvider, getContext())
    func getDiscoveryContext() async throws -> String? {
        let appName = accessSnapshot?.focusedAppName
        let focusedDescription = try? await accessSnapshot?.focus?.getComprehensiveDescription()

        return String.build {
            if let appName, !appName.isEmpty {
                "The focused app is \(appName)"
            } else {
                "There is no focused app"
            }

            "\n"

            if let focusedDescription, !focusedDescription.isEmpty {
                "The focused element is \(focusedDescription)"
            } else {
                "There is no focused element"
            }
        }
    }

    @_implements(StepCapabilityProvider, getContext())
    func getStepContext() async throws -> String? {
        let discovery = try await getDiscoveryContext()!
        let descriptions = try await generateElementDescriptions()

        return String.build {
            discovery

            "\n"

            "The actionable elements are:"
            for description in descriptions {
                if let description = description.bulletPointDescription {
                    description
                }
            }
        }
    }

    func execute(function: LLMFuncCall) async throws {
        // validate the function call. TODO: allow multiple function calls

        guard let function = function as? FunctionCall,
              function.name == "executeAction" else {
            throw LLMCommunicationError.invalidFunctionCall
        }

        // Execute the actions

        // validate that the parameters are present
        guard
            case let .string(itemDesc) = function.args["itemDescription"],
            case let .string(actionName) = function.args["actionName"],
            let lastComponent = itemDesc.split(separator: " ").last,
            let uuid = UUID(uuidString: String(lastComponent))
        else {
            logger.error("Model responded with a missing parameter.")
            throw LLMCommunicationError.invalidFunctionCall
        }

        guard actionName.hasPrefix("AX") && !actionName.contains(" ") else {
            throw LLMCommunicationError.actionFormatInvalid
        }

        guard let element = elementMap[uuid] else {
            throw LLMCommunicationError.elementNotFound
        }

        guard element.actions.contains(actionName) else {
            throw LLMCommunicationError.actionNotFound
        }

        try await element.element.performAction(actionName)
    }

    func functionFailed() {}

    public func generateElementDescriptions() async throws -> [ActionableElementDescription] {
        guard let accessSnapshot else {
            throw LLMCommunicationError.accessSnapshotNotFound
        }

        let screenElements = accessSnapshot.actionableItems.filter { !$0.isMenuBarItem }
        var menuBarItems: [ActionableElement] = []

        for item in accessSnapshot.actionableItems {
            guard item.isMenuBarItem else { continue }
            guard try await item.element.roleMatches(oneOf: [
                .menuItem,
                .menuBarItem
            ]) else { continue }

            menuBarItems.append(item)
        }

        var elementMap: [UUID: ActionableElement] = [:]
        var descriptions: [ActionableElementDescription] = []

        for element in screenElements {
            // get info about the element, verify it exists
            let role = try await element.element.getAttribute(ElementAttribute.roleDescription) as? String
            let description = try await element.element.getDescription()
            let actions = element.actions
            guard let role, let description else { continue }

            // store it and the ID
            let uuid = UUID()
            elementMap[uuid] = element

            // describe its actions
            var actionDescriptions: [ActionableElementDescription.ActionDescription] = []
            for action in actions {
                guard
                    let description = try await element.element.describeAction(action),
                    !description.isEmpty
                else { continue }

                actionDescriptions.append(.init(
                    actionName: action,
                    description: description
                ))
            }

            // append it
            descriptions.append(
                .init(
                    id: uuid,
                    role: role,
                    givenDescription: description,
                    actions: actionDescriptions
                )
            )
        }

        self.elementMap = elementMap

        return descriptions
    }
}
