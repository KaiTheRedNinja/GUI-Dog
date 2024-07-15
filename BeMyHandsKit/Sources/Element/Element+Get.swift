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

    /// Returns the title of the `titleElement`, if it exists
    func getTitleElementTitle() throws -> String? {
        // if this item has a titleElement attribute, get the title from it
        if let titleElement = try getAttribute(.titleElement) as? Element,
           let title = try titleElement.getAttribute(.value) as? String {
            return title
        }

        return nil
    }

    /// Returns the role of the element
    func getRole() throws -> ElementRole? {
        try self.getAttribute(.roleDescription) as? ElementRole
    }

    /// Returns the description of the element
    func getDescription() throws -> String? {
        var descriptions = try [
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

        // if this item has a titleElement attribute, get the title from it
        if let title = try getTitleElementTitle() {
            descriptions.append(title)
        }

        let descriptionString: String?

        if descriptions.contains(where: { $0 != "" }) {
            descriptionString = descriptions.joined(separator: " ")
        } else {
            descriptionString = nil
        }

        return descriptionString
    }

    /// Returns the descriptions of the actions that this element supports
    func getActionDescriptions() throws -> [String] {
        let actions = try self.listActions()
        return try actions.compactMap {
            try self.describeAction($0)
        }
    }

    /// Obtains a comprehensive description of this element. It groups them into three categories:
    /// - The role and subrole of the item
    /// - The descriptions, identifier, or value of the item
    /// - The available actions, if any
    func getComprehensiveDescription() throws -> String {
        let roleString = try getRole()?.rawValue
        let descriptionString = try getDescription()
        let actionsString = try self.getActionDescriptions().joined(separator: " ")

        let descriptionItems = [
            roleString,
            descriptionString,
            actionsString.isEmpty ? nil : actionsString
        ]
        .compactMap { $0 }

        return descriptionItems.joined(separator: ", ")
    }
}
