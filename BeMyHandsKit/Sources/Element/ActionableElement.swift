//
//  ActionableElement.swift
//  
//
//  Created by Kai Quan Tay on 8/7/24.
//

import Foundation

/// Defines the data of an element with actions
public class ActionableElement {
    /// The element that this contains
    public var element: Element

    /// The actions that the element supports
    public var actions: [String]

    /// The frame of the element, if it has one
    public var frame: NSRect?

    /// The attributes of the element
    public var attributes: [String: String]

    public init(element: Element, actions: [String], frame: NSRect?, attributes: [String : String]) {
        self.element = element
        self.actions = actions
        self.frame = frame
        self.attributes = attributes
    }

    /// A description of this actionable element
    public var description: String {
        """
        ActionableElement {
            actions: [\(actions.joined(separator: ", "))],
            frame: \(frame?.debugDescription ?? "nil"),
            attributes: \(attributes)
        }
        """
    }
}
