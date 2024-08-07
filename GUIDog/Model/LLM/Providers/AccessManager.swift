//
//  AccessManager.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 9/7/24.
//

import SwiftUI
import Access
import Element
import OSLog

private let logger = Logger(subsystem: #fileID, category: "GUIDog")

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
            logger.error("Could not create access")
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            logger.info("Exiting")
            await NSApplication.shared.terminate(nil)
            return
        }

        // Set the timeout to 5 seconds
        await access.setTimeout(seconds: 5)

        // Save the Access instance
        self.access = access
    }

    /// Takes an access snapshot, and updates the overlay
    /// - Parameter includeElements: Whether or not interactable elements should be included
    public func takeAccessSnapshot(includeElements: Bool) async throws {
        guard let access else { return }

        let snapshot = try await access.takeAccessSnapshot(includeElements: includeElements)

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
