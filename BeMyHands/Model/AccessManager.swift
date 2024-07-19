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

    /// The ``OverlayManager`` instance, which manages the overlay window. This is
    /// purely for the sake of the sighted, to understand a bit more what is going on.
    internal var overlayManager: OverlayManager?

    /// A snapshot of the accessibility items, plus some contextual information. May not be up-to-date.
    internal var accessSnapshot: AccessSnapshot?

    /// The element map, a map of UUIDs to elements, for use during LLMs
    internal var elementMap: [UUID: ActionableElement]

    @MainActor
    init() {
        self.access = nil
        self.overlayManager = .init()
        self.accessSnapshot = nil
        self.elementMap = [:]
    }

    /// Whether access is defined. This is false when either access has not been granted, or ``setup()`` has not 
    /// been called.
    var accessAvailable: Bool {
        access != nil
    }

    /// Sets up the `access` and `overlayManager`
    func setup() async {
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

        // Assign self as the delegate for access
        Task { @AccessActor in
            access.delegate = self
        }

        // Save the Access instance
        self.access = access

        // Show the overlay, initially with no data
        await overlayManager?.show()
    }

    /// Takes an access snapshot, and updates the overlay
    func takeAccessSnapshot() async throws {
        guard let access else { return }

        let snapshot = try await access.takeAccessSnapshot()

        self.accessSnapshot = snapshot

        await updateOverlayFrames()
    }

    /// Updates the overlay ui with the latest actionable items and focused window
    func updateOverlayFrames() async {
        // if the access snapshot doesn't exist, pass [] instead
        await overlayManager?.update(actionableElements: accessSnapshot?.actionableItems ?? [])
    }
}

extension AccessManager: AccessDelegate {
    func accessDidRefocus(success: Bool) {
        print("Access refocused!")
        // Note: we do not call update anymore, because we wait for the
        // LLM calling to do it itself.
    }
}
