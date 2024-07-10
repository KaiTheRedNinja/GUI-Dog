//
//  Element+Get.swift
//  
//
//  Created by Kai Quan Tay on 10/7/24.
//

import ApplicationServices

public extension Element {
    /// Creates the element corresponding to the application of the specified element.
    /// - Returns: Application element.
    func getApplication() throws -> Element {
        let processIdentifier = try getProcessIdentifier()
        return Element(processIdentifier: processIdentifier)
    }

    /// Reads the process identifier of this element.
    /// - Returns: Process identifier.
    func getProcessIdentifier() throws -> pid_t {
        let legacyValue = legacyValue as! AXUIElement
        var processIdentifier = pid_t(0)
        let result = AXUIElementGetPid(legacyValue, &processIdentifier)
        let error = ElementError(from: result)
        switch error {
        case .success:
            break
        case .apiDisabled, .invalidElement, .notImplemented, .timeout:
            throw error
        default:
            fatalError("Unexpected error reading an accessibility element's process identifier: \(error)")
        }
        return processIdentifier
    }

    /// Obtains a description of this element. It groups them into three categories:
    /// - The role and subrole of the item
    /// - The descriptions, identifier, or value of the item
    /// - The available actions, if any
    func getDescription() throws -> String {
        let roleString = try self.getAttribute(.roleDescription) as? String

        let descriptions = try [
            ElementAttribute.help,
            .title,
            .description,
            .value,
            .minValue,
            .maxValue,
            .valueIncrement,
            .allowedValues,
            .menuItemCmdChar,
            .valueDescription
        ].compactMap { item in
            try self.getAttribute(item) as? String
        }

        let descriptionString: String?

        if descriptions.isEmpty {
            descriptionString = nil
        } else {
            descriptionString = descriptions.joined(separator: " ")
        }

        let actions = try self.listActions()

        let actionString: String?

        if actions.isEmpty {
            actionString = nil
        } else {
            actionString = actions.joined(separator: " ")
        }

        let descriptionItems = [roleString, descriptionString, actionString].compactMap { $0 }

        return descriptionItems.joined(separator: ", ")
    }
}
