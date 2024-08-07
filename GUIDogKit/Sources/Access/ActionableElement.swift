//
//  ActionableElement.swift
//  
//
//  Created by Kai Quan Tay on 8/7/24.
//

import Foundation
import Element

/// Defines the data of an element with actions
public struct ActionableElement {
    /// The element that this contains
    public var element: Element

    /// The actions that the element supports
    public var actions: [String]

    /// The frame of the element, if it has one
    public var frame: NSRect?

    /// Creates an actionable element from its base attributes
    public init(
        element: Element,
        actions: [String],
        frame: NSRect?
    ) {
        self.element = element
        self.actions = actions
        self.frame = frame
    }
}

/// A node in a tree representing actionable elements
public struct ActionableElementNode {
    /// A description of this element
    public var elementDescription: String
    /// The actionable element of this element, if this element is actionable
    public var actionableElement: ActionableElement?
    /// The children of this element
    public var children: [ActionableElementNode]
}
