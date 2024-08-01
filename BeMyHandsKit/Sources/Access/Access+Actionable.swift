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
    /// Returns all actionable elements of the focused application
    @MainActor
    public func actionableElements() async throws -> [ActionableElement]? {
        guard let application = await application else {
            return nil
        }
        let actionable = try await treeActionableElements(application)
//        let actionable = try await recursiveActionableElements(application)
//        return actionable
        fatalError()
    }

    /// Returns a snapshot of the current accessibility state
    @MainActor
    public func takeAccessSnapshot(includeElements: Bool = false) async throws -> AccessSnapshot? {
        // TODO: consider using AccessGenericReader to get extra context for elements

        // Get actionable elements
        guard let elements = includeElements ? try await actionableElements() : [] else {
            logger.warning("No elements found")
            return nil
        }

        // Get the app name and focused element
        let appName = try await application?.getAttribute(.title) as? String
        let focusElement = await focus

        return AccessSnapshot(
            focusedAppName: appName,
            focus: focusElement,
            actionableItems: elements
        )
    }

    /// Returns all actionable elements within this element, including both children and itself.
    /// - Parameters:
    ///   - element: The root node of the element tree to search for actionable elements in
    ///   - maxChildren: The maximum number of children to explore. Generally, they are explored left-to-right,
    /// - Returns: Actionable elements under this element. If `element` is actionable, it will be the first item in the
    /// returned array. It will return nil if the element is invalid.
    @ElementActor
    private func recursiveActionableElements(
        _ element: Element,
        maxChildren: Int = 30
    ) async throws -> [ActionableElement]? {
        do {
            var elements: [ActionableElement] = []

            if let selfAction = try element.createActionableElement() {
                elements.append(selfAction)
            }

            // TODO: fix description, make it dependent on AccessReader
            let reader = try await AccessReader(for: element)
            let description = try await reader.read()
                .compactMap { semantic in
                    let desc = semantic.description
                    return desc.isEmpty ? nil : desc
                }
                .joined(separator: ", ")

            // get the children's actionable items
            guard let children = try element.getAttribute(.childElements) as? [Any?] else {
                return elements
            }

            var childrenActionableItems = [ActionableElement]()
            for (index, child) in children.lazy.compactMap({ $0 as? Element }).enumerated() {
                guard index < maxChildren else {
                    logger.info("Hit children limit")
                    break
                }

                guard let childActionableItems = try await recursiveActionableElements(
                    child,
                    maxChildren: maxChildren
                ) else {
                    continue
                }

                // add self's description as the latest ancestor of the children
                let newChildActionableItems = childActionableItems.map {
                    var newItem = $0
                    newItem.ancestorDescriptions.append(description)
                    return newItem
                }

                childrenActionableItems.append(contentsOf: newChildActionableItems)
            }
            elements.append(contentsOf: childrenActionableItems)

            return elements
        } catch ElementError.invalidElement, ElementError.timeout {
            return nil
        } catch {
            throw error
        }
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
            let selfAction = try element.createActionableElement()

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
}

/// A node in a tree representing actionable elements
struct ActionableElementNode {
    /// A description of this element
    var elementDescription: String
    /// The actionable element of this element, if this element is actionable
    var actionableElement: ActionableElement?
    /// The children of this element
    var children: [ActionableElementNode]
}
