//
//  LLMManager.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 19/7/24.
//

import Foundation
import Access

/// A class that facilitates the conversation with an LLM. This manager should be RESET
/// for every conversation.
class LLMManager {
    /// The accessibility item provider. Note that this should be defined as soon as possible before
    /// any other methods are called.
    var accessibilityItemProvider: AccessibilityItemProvider!

    /// The UI delegate, which is informed of when the UI should update to reflect the manager's
    /// internal state. Optional.
    var uiDelegate: LLMDisplayDelegate?

    /// The current state
    var state: LLMState = .init(goal: "No Goal", steps: [])

    /// Creates a blank `LLMManager`
    init(
        accessibilityItemProvider: AccessibilityItemProvider! = nil,
        uiDelegate: LLMDisplayDelegate? = nil
    ) {
        self.accessibilityItemProvider = accessibilityItemProvider
        self.uiDelegate = uiDelegate
    }
}

/// Describes an accessibility object
struct ActionableElementDescription {
    /// A UUID to uniquely identify the object
    var id: UUID
    /// The role of the object
    var role: String
    /// The given description of the object
    var givenDescription: String
    /// The actions that the object accepts
    var actions: [ActionDescription]

    /// Describes an accessibility action
    struct ActionDescription {
        /// The name of the action, prefixed with "AX"
        var actionName: String
        /// The description of the action
        var description: String
    }

    /// Describes itself in a bullet point form. If the given description or actions are empty, this returns nil.
    var bulletPointDescription: String? {
        guard !givenDescription.isEmpty, !actions.isEmpty else { return nil }

        let desc = role + ": " + givenDescription + ": " + id.uuidString

        return String.build {
            " - " + desc

            for action in actions where action.actionName != "AXCancel" {
                "    - " + action.actionName + (
                    action.description.isEmpty
                    ? ""
                    : ": " + action.description
                )
            }
        }
    }
}

/// Provides accessibility information to an ``LLMManager``.
protocol AccessibilityItemProvider: AnyObject {
    /// Requests the provider to update its catalog of accessibility objects
    func updateAccessibilityObjects() async throws

    /// Requests the provider to provide the name of the current app. Nil if no app is focused.
    func getCurrentAppName() async -> String?
    /// Requests the provider to provide a description of the currently focused element. Nil if no
    /// element is focused.
    func getFocusedElementDescription() async -> String?

    /// Requests the provider to generate descriptions for accessibility objects and return them.
    /// Note that it should RANDOMLY generate `id`s for each element, and results for this
    /// function should NEVER be cached by the provider.
    ///
    /// This should NOT return menu bar events.
    func generateElementDescriptions() async throws -> [ActionableElementDescription]
    /// Requests the provider to execute an action on an element with a given ID
    func execute(action: String, onElementID elementID: UUID) async throws
}

/// Provides a UI to the ``LLMManager``.
///
/// Note that the `LLMManager` only informs the display delegate about changes in the LLM
/// communication state. The ``AccessibilityItemProvider`` is responsible for updating
/// the UI directly about actionable elements.
protocol LLMDisplayDelegate: AnyObject {
    /// Shows the display UI
    func show() async
    /// Hides the display UI
    func hide() async
    /// Updates the display UI with a new state
    func update(state: LLMState) async
}
