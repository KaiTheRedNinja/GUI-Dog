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
public class AccessSnapshot {
    /// The name of the currently focused app
    public var focusedAppName: String?

    /// The currently focused element
    public var focus: Element?

    /// The actionable items visible on screen
    public var actionableItems: [ActionableElement]

    /// Creates an AccessSnapshot from its base attributes
    public init(focusedAppName: String?, focus: Element? = nil, actionableItems: [ActionableElement]) {
        self.focusedAppName = focusedAppName
        self.focus = focus
        self.actionableItems = actionableItems
    }
}
