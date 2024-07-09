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

    /// The actionable items visible on screen. May not be up-to-date.
    private var actionableItems: [ActionableElement]

    @MainActor
    init() {
        self.access = nil
        self.overlayManager = .init()
        self.actionableItems = []
    }

    /// Whether access is defined. This is false when either access has not been granted, or ``setup()`` has not been called.
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

        // Set the timeout to 5 seconds
        await access.setTimeout(seconds: 5.0)

        // Assign self as the delegate for access
        Task { @AccessActor in
            access.delegate = self
        }

        // Save the Access instance
        self.access = access

        // Show the overlay, initially with no data
        await overlayManager.show()
    }

    /// Refreshes the `actionableItems` by determining the actionable elements of the currently focused app
    func refreshActionableItems() async throws {
        guard let access else { return }

        // Get actionable elements
        guard let elements = try await access.actionableElements() else {
            print("No elements found")
            return
        }

        // Only show the following data, if they exist:
        let items = [
            kAXRoleAttribute,
            kAXSubroleAttribute,
            kAXHelpAttribute,
            kAXTitleAttribute,
            kAXRoleDescriptionAttribute,
            kAXIdentifierAttribute,
            kAXDescriptionAttribute,
            kAXValueAttribute,
            kAXMinValueAttribute,
            kAXMaxValueAttribute,
            kAXValueIncrementAttribute,
            kAXAllowedValuesAttribute,
            kAXMenuItemCmdCharAttribute,
            "AXAttributedDescription",
            "AXFrame"
        ]

        // Reduce the number of attributes they have, for pretty printing
        let concise = elements.compactMap { element in
            var attributes: [String: String] = [:]

            for item in items {
                attributes[item] = element.attributes[item]
            }

            let conciseAncestors = element.ancestorDescriptions.filter { $0.contains(", ") }

            return ActionableElement(
                element: element.element,
                actions: element.actions,
                frame: element.frame,
                attributes: attributes,
                ancestorDescriptions: conciseAncestors
            )
        }

        self.actionableItems = concise

        try await updateOverlay()
    }

    func updateOverlay() async throws {
        // Get the focused window element
        guard let focusedWindow = try await access?.focusedWindow() else { return }

        // Update the manager
        await overlayManager.update(with: focusedWindow, actionableElements: actionableItems)
    }
}

extension AccessManager: AccessDelegate {
    func accessDidRefocus(success: Bool) {
        print("Access refocused!")
        Task {
            try await refreshActionableItems()
        }
    }
}
