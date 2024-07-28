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

    /// Returns the descriptions of the actions that this element supports
    func getActionDescriptions() throws -> [String] {
        let actions = try self.listActions()
        return try actions.compactMap {
            try self.describeAction($0)
        }
    }
}
