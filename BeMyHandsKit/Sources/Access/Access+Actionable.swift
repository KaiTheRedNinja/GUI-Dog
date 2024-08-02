//
//  Access+Actionable.swift
//  BeMyHandsKit
//
//  Created by Kai Quan Tay on 1/8/24.
//

import Element
import OSLog

private let logger = Logger(subsystem: #fileID, category: "Access")

extension Access {
    /// Returns all actionable elements of the focused application, as a tree
    @MainActor
    public func actionableElements() async throws -> ActionableElementNode? {
        guard let application = await application else {
            return nil
        }
        let actionable = try await treeActionableElements(application)
        return actionable
    }

    /// Returns a snapshot of the current accessibility state
    @MainActor
    public func takeAccessSnapshot(includeElements: Bool = false) async throws -> AccessSnapshot? {
        // TODO: consider using AccessGenericReader to get extra context for elements

        // Get actionable elements
        let elements: ActionableElementNode?

        if includeElements {
            if let elem = try await actionableElements() {
                elements = elem
            } else {
                logger.warning("No elements found")
                return nil
            }
        } else {
            elements = nil
        }

        // Get the app name and focused element
        let appName = try await application?.getAttribute(.title) as? String
        let focusElement = await focus

        return AccessSnapshot(
            focusedAppName: appName,
            focus: focusElement,
            actionTree: elements
        )
    }

    /// Returns all actionable elements within this element, including both children and itself, as a tree
    /// - Parameters:
    ///   - element: The root node of the element tree to search for actionable elements in
    ///   - maxChildren: The maximum number of children to explore. Generally, they are explored left-to-right,
    /// - Returns: The node element of a tree representing the child actionable elements of this element. Nil if
    /// the element does not exist or has no actionable children.
    @ElementActor
    private func treeActionableElements(
        _ element: Element,
        maxChildren: Int = 30
    ) async throws -> ActionableElementNode? {
        do {
            // get self description
            let reader = try await AccessReader(for: element)
            let description = try await reader.read()
                .compactMap { semantic in
                    let desc = semantic.description
                    return desc.isEmpty ? nil : desc
                }
                .joined(separator: ", ")
            let selfAction = try createActionableElement(from: element)

            // create self node
            var elementNode: ActionableElementNode = .init(
                elementDescription: description,
                actionableElement: selfAction,
                children: []
            )

            var childrenNodes: [ActionableElementNode] = []

            // get the children's actionable items
            guard let children = try element.getAttribute(.childElements) as? [Any?] else {
                if selfAction == nil { // if there are no children and this element is not actionable, return nil
                    return nil
                } else {
                    return elementNode
                }
            }

            for (index, child) in children.lazy.compactMap({ $0 as? Element }).enumerated() {
                guard index < maxChildren else {
                    logger.info("Hit children limit")
                    break
                }

                guard let childNode = try await treeActionableElements(
                    child,
                    maxChildren: maxChildren
                ) else {
                    continue
                }

                childrenNodes.append(childNode)
            }

            elementNode.children = childrenNodes

            // if children is empty and self is non actionable, return nil
            if childrenNodes.isEmpty && selfAction == nil {
                return nil
            }

            return elementNode
        } catch ElementError.invalidElement, ElementError.timeout {
            return nil
        } catch {
            throw error
        }
    }

    /// Converts this element into an ``ActionableElement``. Throws if any steps fail, returns nil if this
    /// element is not actionable.
    @ElementActor
    private func createActionableElement(from element: Element) throws -> ActionableElement? {
        let actions = try element.listActions()

        // if this element is non-actionable, return
        guard !actions.isEmpty else { return nil }

        // if it is valid actionable, add it and its description
        let frameAttribute = try element.getAttribute(.frame)

        // obtain the frame of the actionable element
        let frame = frameAttribute as? NSRect

        // create the element
        return .init(
            element: element,
            actions: actions,
            frame: frame
        )
    }
}
