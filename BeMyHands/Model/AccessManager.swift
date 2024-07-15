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
    private var overlayManager: OverlayManager

    /// A snapshot of the accessibility items, plus some contextual information. May not be up-to-date.
    private var accessSnapshot: AccessSnapshot?

    @MainActor
    init() {
        self.access = nil
        self.overlayManager = .init()
        self.accessSnapshot = nil
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
        await overlayManager.show()
    }

    /// Takes an access snapshot, and updates the overlay
    func takeAccessSnapshot() async throws {
        guard let access else { return }

        let snapshot = try await access.takeAccessSnapshot()

        self.accessSnapshot = snapshot

        try await updateOverlay()
    }

    /// Updates the overlay ui
    func updateOverlay() async throws {
        // Get the focused window element
        guard
            let focusedWindow = try await access?.focusedWindow(),
            let accessSnapshot
        else { return }

        // Update the manager
        await overlayManager.update(with: focusedWindow, actionableElements: accessSnapshot.actionableItems)
    }

    /// Requests actions from the Gemini API based on a request and the current `accessSnapshot`
    func requestLLMAction() async throws {
        guard let accessSnapshot else { return }

        let screenElements = accessSnapshot.actionableItems.filter { !$0.isMenuBarItem }
        let menuBarItems = accessSnapshot.actionableItems.filter { $0.isMenuBarItem }

        let prompt = try await String.build {
            if let focusedAppName = accessSnapshot.focusedAppName {
                "The focused app is \(focusedAppName)"
            } else {
                "There is no focused app"
            }

            "\n"

            if let focus = accessSnapshot.focus {
                "The focused element is \(try await focus.getDescription())"
            } else {
                "There is no focused element"
            }

            "\n"

            "The actionable elements are:"
            for actionableItem in screenElements {
                " - " + (try await actionableItem.element.getDescription())
            }

            "\n"

            "The menu bar items are:"
            for menuBarItem in menuBarItems {
                try await menuBarItem.element.getDescription()
            }
        }

        print("Prompt: \n\(prompt)")
    }
}

extension AccessManager: AccessDelegate {
    func accessDidRefocus(success: Bool) {
        print("Access refocused!")
        Task {
            try await takeAccessSnapshot()
        }
    }
}
