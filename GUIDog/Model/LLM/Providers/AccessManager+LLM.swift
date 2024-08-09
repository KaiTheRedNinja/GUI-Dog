//
//  AccessManager+LLM.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 15/7/24.
//

import Foundation
import Access
import Element
import HandsBot
import GoogleGenerativeAI
import OSLog

private let logger = Logger(subsystem: #fileID, category: "GUIDog")

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

        To use this tool, use the `executeAction` function call. When you call the function to execute an action \
        on the element, refer to the element by its `description` AND `UUID` EXACTLY as it is given in \
        [description]: [UUID] and the action by its `action name`. You MUST include the UUID in the \
        `itemDescription` field.
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

    func updateDiscoveryContext() async throws {
        // don't include elements, just to be faster
        try await takeAccessSnapshot(includeElements: false)
        await uiDelegate?.update(actionableElements: [])
    }

    func updateContext() async throws {
        logger.info("Updating context!")
        try await takeAccessSnapshot(includeElements: true)
        await uiDelegate?.update(actionableElements: accessSnapshot?.actionableItems ?? [])
        logger.info("Updated context!")
    }

    func getDiscoveryContext() async throws -> String? {
        let appName = accessSnapshot?.focusedAppName
        let focusedDescription = try? await accessSnapshot?.focus?.reader.read()
            .compactMap { semantic in
                let desc = semantic.description
                return desc.isEmpty ? nil : desc
            }
            .joined(separator: ", ")

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

    func getContext() async throws -> String? {
        let discovery = try await getDiscoveryContext()!
        let description = try await generateElementDescriptions()

        return String.build {
            discovery

            "\n"

            "The actionable elements are:"
            description
        }
    }

    func execute(function: LLMFuncCall) async throws {
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
            throw AccessError.actionFormatInvalid
        }

        guard let element = elementMap[uuid] else {
            throw AccessError.elementNotFound
        }

        guard element.actions.contains(actionName) else {
            throw AccessError.actionNotFound
        }

        try? await element.element.performAction(actionName)
    }

    func functionFailed() {}

    public func generateElementDescriptions() async throws -> String {
        guard let accessSnapshot, let actionTree = accessSnapshot.actionTree else {
            throw AccessError.accessSnapshotNotFound
        }

        var elementMap: [UUID: ActionableElement] = [:]
        let description = await describe(node: actionTree, elementMap: &elementMap) ?? ""
        self.elementMap = elementMap

        return description
    }

    func describe(node: ActionableElementNode, elementMap: inout [UUID: ActionableElement]) async -> String? {
        // exclude menu bars, menus, and menu items
        let isMenuBar = try? await node.actionableElement?.element.roleMatches(oneOf: [.menuBar, .menu, .menuItem])
        guard (isMenuBar ?? false) == false else { return nil }

        var actionDescription: String?

        if let actionableElement = node.actionableElement {
            do {
                actionDescription = try await describe(element: actionableElement, elementMap: &elementMap)
            } catch {
                logger.error("Could not get description for element: \(node.elementDescription)")
            }
        }

        // this has a single child, we can give an abridged version of the description
        // even if it is actionable, we ignore the action because the lower child takes precedence.
        //
        // If the child description is nil, we do not generate an abridged description and instead use the full one.
        if node.children.count == 1,
           let childDesc = await describe(node: node.children.first!, elementMap: &elementMap) {
            return " - " + node.elementDescription + childDesc
        }

        // else, it has either 0 or more than 1 child.
        return await String.build {
            if let actionDescription {
                " - " + node.elementDescription + ": " + actionDescription
            } else {
                " - " + node.elementDescription
            }

            // has multiple children
            if node.children.count > 1 {
                " - Children:"
                    .tab()
                for child in node.children {
                    if let childDesc = await describe(node: child, elementMap: &elementMap) {
                        childDesc
                            .tab(count: 4)
                    }
                }
            }
        }
    }

    func describe(element: ActionableElement, elementMap: inout [UUID: ActionableElement]) async throws -> String? {
        let actions = element.actions

        // store it and the ID
        let uuid = UUID()
        elementMap[uuid] = element

        // describe its actions
        var actionDescriptions: [(actionName: String, description: String)] = []
        for action in actions {
            guard
                let description = try await element.element.describeAction(action),
                !description.isEmpty
            else { continue }

            actionDescriptions.append((
                actionName: action,
                description: description
            ))
        }

        // return it
        return String.build {
            uuid.uuidString

            for (actionName, actionDescription) in actionDescriptions where actionName != "AXCancel" {
                (
                    " - " + actionName + (
                        actionDescription.isEmpty
                        ? ""
                        : ": " + actionDescription
                    )
                )
                .tab()
            }
        }
    }
}

/// A custom version of `ElementAction`, which defines actions that don't exist.
///
/// We just use this to pretend it exists, to perform actions that the element doesn't support as actions but instead
/// exposes as mutable parameters.
enum CustomAction: String {
    case becomeFocus = "AXBecomeFocus"
    case resignFocus = "AXResignFocus"
}

enum AccessError: LLMOtherError {
    case actionFormatInvalid
    case elementNotFound
    case actionNotFound
    case accessSnapshotNotFound

    var description: String {
        switch self {
        case .actionFormatInvalid: "The LLM's response was malformed"
        case .elementNotFound: "The LLM mentioned a nonexistent item on screen"
        case .actionNotFound: "The LLM tried to perform an unsupported action"
        case .accessSnapshotNotFound: "GUI Dog could not obtain information about the current state of the screen"
        }
    }
}

#if hasFeature(RetroactiveAttribute)
extension ElementError: @retroactive LLMOtherError {
    @_implements(LLMOtherError, description)
    public var otherErrorDescription: String {
        elementErrorDescription(self)
    }
}
#else
extension ElementError: LLMOtherError {
    @_implements(LLMOtherError, description)
    public var otherErrorDescription: String {
        elementErrorDescription(self)
    }
}
#endif

private func elementErrorDescription(_ error: ElementError) -> String {
    switch error {
    case .success: "Success"
    case .systemFailure: "The accessibility system failed to respond"
    case .illegalArgument: "GUI Dog incorrectly used the accessibility system"
    case .invalidElement: "GUI Dog tried to perform an action on an on-screen item that doesn't exist"
    case .invalidObserver: "GUI Dog referenced an observer that doesn't exist"
    case .timeout: "The accessibility system took too long to respond to GUI Dog's request"
    case .attributeUnsupported: "GUI Dog tried to access an unsupported attribute"
    case .actionUnsupported: "GUI Dog tried to perform an unsupported action"
    case .notificationUnsupported: "GUI Dog tried to watch for on-screen changes in something that does not exist"
    case .notImplemented: "GUI Dog tried to do something that is not implemented by the accessibility system"
    case .notificationAlreadyRegistered: "GUI Dog tried to watch for on-screen changes, but it is already watching"
    case .notificationNotRegistered: "GUI Dog failed to watch for on-screen changes"
    case .apiDisabled: "GUI Dog has not been granted accessibility permissions"
    case .noValue: "GUI Dog tried to access an attribute that has no value"
    case .parameterizedAttributeUnsupported: "GUI Dog tried to access a parameterized attribute that does not exist"
    case .notEnoughPrecision: "GUI Dog tried to access an attribute with a precision that is too low"
    }
}
