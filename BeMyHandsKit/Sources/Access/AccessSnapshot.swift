//
//  AccessSnapshot.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 10/7/24.
//

import Foundation
import Element

/// A "snapshot" of the accessibility elements currently on screen, plus some contextual data about the currently 
/// focused app and element.
///
/// **Not guarenteed** to be up-to-date at any point in time, **including directly after creation**.
public struct AccessSnapshot {
    /// The name of the currently focused app
    public var focusedAppName: String?

    /// The currently focused element
    public var focus: AccessFocus?

    /// The actionable items visible on screen
    public var actionableItems: [ActionableElement]

    /// The actionable items visible on screen, organised as a tree
    public var actionTree: ActionableElementNode?

    /// Creates an AccessSnapshot from its base attributes
    init(
        focusedAppName: String? = nil,
        focus: AccessFocus? = nil,
        actionTree: ActionableElementNode? = nil
    ) {
        self.focusedAppName = focusedAppName
        self.focus = focus
        self.actionTree = actionTree

        // bulid the actionable elements via depth-first-search
        self.actionableItems = []
        var nodes = [actionTree]
        while !nodes.isEmpty {
            guard let node = nodes.removeLast() else { break }
            if let actionableElement = node.actionableElement {
                self.actionableItems.append(actionableElement)
            }
            // reverse the children so that the first child is explored first
            nodes.append(contentsOf: node.children.reversed())
        }
    }
}
