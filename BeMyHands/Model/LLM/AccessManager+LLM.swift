//
//  AccessManager+LLM.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 15/7/24.
//

import Foundation
import Element
import GoogleGenerativeAI

extension AccessManager: AccessibilityItemProvider {
    func updateAccessibilityObjects() async throws {
        try await takeAccessSnapshot()
        await overlayManager?.update(actionableElements: accessSnapshot?.actionableItems ?? [])
    }

    func getCurrentAppName() -> String? {
        accessSnapshot?.focusedAppName
    }

    func getFocusedElementDescription() -> String? {
        try? accessSnapshot?.focus?.getComprehensiveDescription()
    }

    func generateElementDescriptions() async throws -> [ActionableElementDescription] {
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
            let role = try await element.element.getAttribute(.roleDescription) as? String
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

    func execute(action: String, onElementID elementID: UUID) async throws {
        guard action.hasPrefix("AX") && !action.contains(" ") else {
            throw LLMCommunicationError.actionFormatInvalid
        }

        guard let element = elementMap[elementID] else {
            throw LLMCommunicationError.elementNotFound
        }

        guard element.actions.contains(action) else {
            throw LLMCommunicationError.actionNotFound
        }

        try await element.element.performAction(action)
    }
}
