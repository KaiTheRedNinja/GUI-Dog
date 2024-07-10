//
//  Element+Action.swift
//  
//
//  Created by Kai Quan Tay on 10/7/24.
//

import ApplicationServices

public extension Element {
    /// Creates a list of all the actions supported by this element.
    /// - Returns: List of actions.
    func listActions() throws -> [String] {
        let legacyValue = legacyValue as! AXUIElement
        var actions: CFArray?
        let result = AXUIElementCopyActionNames(legacyValue, &actions)
        let error = ElementError(from: result)
        switch error {
        case .success:
            break
        case .systemFailure, .illegalArgument:
            return []
        case .apiDisabled, .invalidElement, .notImplemented, .timeout:
            throw error
        default:
            fatalError("Unexpected error reading an accessibility elenet's action names: \(error)")
        }
        guard let actions = [Any?](legacyValue: actions as CFTypeRef) else {
            return []
        }
        return actions.compactMap({ $0 as? String })
    }

    /// Queries for a localized description of the specified action.
    /// - Parameter action: Action to query.
    /// - Returns: Description of the action.
    func describeAction(_ action: String) throws -> String? {
        let legacyValue = legacyValue as! AXUIElement
        var description: CFString?
        let result = AXUIElementCopyActionDescription(legacyValue, action as CFString, &description)
        let error = ElementError(from: result)
        switch error {
        case .success:
            break
        case .actionUnsupported, .illegalArgument, .systemFailure:
            return nil
        case .apiDisabled, .invalidElement, .notImplemented, .timeout:
            throw error
        default:
            fatalError("Unexpected error reading an accessibility element's description for action \(action)")
        }
        guard let description = description else {
            return nil
        }
        return description as String
    }

    /// Performs the specified action on this element.
    /// - Parameter action: Action to perform.
    func performAction(_ action: String) throws {
        let legacyValue = legacyValue as! AXUIElement
        let result = AXUIElementPerformAction(legacyValue, action as CFString)
        let error = ElementError(from: result)
        switch error {
        case .success, .systemFailure, .illegalArgument:
            break
        case .actionUnsupported, .apiDisabled, .invalidElement, .notImplemented, .timeout:
            throw error
        default:
            print("Unexpected error performing accessibility element action \(action): \(error.localizedDescription)")
        }
    }

    /// Converts this element into an ``ActionableElement``. Throws if any steps fail, returns nil if this
    /// element is not actionable.
    func createActionableElement() throws -> ActionableElement? {
        let actions = try listActions()

        // if this element is actionable, add it and its description
        guard !actions.isEmpty else { return nil }
        let attributes = try listAttributes()
        var attributeValues = [String: Any]()
        for attribute in attributes {
            guard let value = try getAttribute(attribute) else {
                continue
            }
            attributeValues[attribute] = encode(value: value)
        }

        // if this item has a titleElement attribute, get the title from it
        if attributes.contains(ElementAttribute.titleElement.rawValue),
           let titleElement = try getAttribute(.titleElement) as? Element,
           let title = try titleElement.getAttribute(.value) as? String {

            attributeValues[ElementAttribute.title.rawValue] = title
        }

        // convert the attributes to string representations
        // NOTE: we may want to consider adding other primatives for flexibility
        var stringAttributes: [String: String] = [:]

        for (key, value) in attributeValues {
            stringAttributes[key] = value as? String
        }

        // obtain the frame of the actionable element
        let frame: NSRect?
        if let rawFrame = attributeValues["AXFrame"] as? [String: CGFloat],
           let x = rawFrame["x"],
           let y = rawFrame["y"],
           let height = rawFrame["height"],
           let width = rawFrame["width"] {
            frame = NSRect(x: x, y: y, width: width, height: height)
        } else {
            frame = nil
        }

        // create the element
        return .init(
            element: self,
            actions: actions,
            frame: frame,
            attributes: stringAttributes,
            ancestorDescriptions: []
        )
    }

    /// Returns all actionable elements within this element, including both children and itself.
    /// - Parameter maxChildren: The maximum number of children to explore. Generally, they are explored left-to-right,
    /// top-to-bottom, though this is not guarenteed.
    /// - Returns: An array of actionable elements, if it worked
    func getActionableElements(maxChildren: Int = 60) async throws -> [ActionableElement]? {
        do {
            var elements: [ActionableElement] = []

            if let selfAction = try createActionableElement() {
                elements.append(selfAction)
            }

            let description = try self.getDescription()

            // get the children's actionable items
            guard let children = try getAttribute("AXChildren") as? [Any?] else {
                return elements
            }

            var childrenActionableItems = [ActionableElement]()
            for (index, child) in children.lazy.compactMap({ $0 as? Element }).enumerated() {
                guard index < maxChildren else {
                    print("Hit children limit")
                    break
                }

                guard let childActionableItems = try await child.getActionableElements(maxChildren: maxChildren) else {
                    continue
                }

                // add self's description as the latest ancestor of the children
                for childActionableItem in childActionableItems {
                    childActionableItem.ancestorDescriptions.append(description)
                }

                childrenActionableItems.append(contentsOf: childActionableItems)
            }
            elements.append(contentsOf: childrenActionableItems)

            return elements
        } catch ElementError.invalidElement {
            return nil
        } catch {
            throw error
        }
    }
}
