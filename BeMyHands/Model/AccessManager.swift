//
//  AccessManager.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 9/7/24.
//

import SwiftUI
import Access
import Element

@Observable
class AccessManager {
    /// The ``Access`` instance, which manages accessing the accessibility API
    private var access: Access?

    /// The ui delegate, which is informed of changes that the UI might want. This is
    /// purely for the sake of the sighted, to understand a bit more what is going on.
    weak var uiDelegate: AccessDisplayDelegate?

    /// A snapshot of the accessibility items, plus some contextual information. May not be up-to-date.
    var accessSnapshot: AccessSnapshot?

    /// The element map, a map of UUIDs to elements, for use during LLMs
    var elementMap: [UUID: ActionableElement]

    @MainActor
    init() {
        self.access = nil
        self.accessSnapshot = nil
        self.elementMap = [:]
    }

    /// Whether access is defined. This is false when either access has not been granted, or ``setup()`` has not 
    /// been called.
    public var accessAvailable: Bool {
        access != nil
    }

    /// Sets up the `access` and `overlayManager`
    public func setup() async {
        // Create the access instance
        guard let access = await Access() else {
            // Could not be created. Usually due to lack of permissions.
            print("Could not create access")
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            print("Exiting")
            await NSApplication.shared.terminate(nil)
            return
        }

        // Set the timeout to 0.5 seconds
        await access.setTimeout(seconds: 0.5)

        // Save the Access instance
        self.access = access

        // Show the overlay, initially with no data
        await uiDelegate?.show()
    }

    /// Takes an access snapshot, and updates the overlay
    public func takeAccessSnapshot() async throws {
        guard let access else { return }

        let snapshot = try await access.takeAccessSnapshot()

        self.accessSnapshot = snapshot

        await updateOverlayFrames()
    }

    /// Updates the overlay ui with the latest actionable items and focused window
    public func updateOverlayFrames() async {
        // if the access snapshot doesn't exist, pass [] instead
        await uiDelegate?.update(actionableElements: accessSnapshot?.actionableItems ?? [])
    }
}

public protocol AccessDisplayDelegate: AnyObject {
    func show() async
    func update(actionableElements: [ActionableElement]) async
}

/// Describes an accessibility object
public struct ActionableElementDescription {
    /// A UUID to uniquely identify the object
    public var id: UUID
    /// The role of the object
    public var role: String
    /// The given description of the object
    public var givenDescription: String
    /// The actions that the object accepts
    public var actions: [ActionDescription]

    /// Describes an accessibility action
    public struct ActionDescription {
        /// The name of the action, prefixed with "AX"
        public var actionName: String
        /// The description of the action
        public var description: String

        /// Creates an accessibility action description
        public init(actionName: String, description: String) {
            self.actionName = actionName
            self.description = description
        }
    }

    /// Creates an accessibility object description
    public init(
        id: UUID,
        role: String,
        givenDescription: String,
        actions: [ActionDescription]
    ) {
        self.id = id
        self.role = role
        self.givenDescription = givenDescription
        self.actions = actions
    }

    /// Describes itself in a bullet point form. If the given description or actions are empty, this returns nil.
    public var bulletPointDescription: String? {
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
