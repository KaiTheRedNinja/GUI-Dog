//
//  ContentView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import SwiftUI
import Access
import Element

struct ContentView: View {
    @State var access: Access?
    @State var overlayManager: OverlayManager?

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            if access != nil {
                Button("Scan focused window after 3 seconds") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                        Task {
                            do {
                                try await overlayActionsOnCurrentWindow()
                            } catch {
                                print("Error making overlay actions: \(error)")
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .task {
            print("Setting up access")
            guard let access = await Access() else {
                print("Could not create access")
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                print("Exiting")
                NSApplication.shared.terminate(nil)
                return
            }

            await access.setTimeout(seconds: 5.0)

            DispatchQueue.main.async {
                self.access = access
            }
        }
    }

    func overlayActionsOnCurrentWindow() async throws {
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

            return ActionableElement(
                element: element.element,
                actions: element.actions,
                frame: element.frame,
                attributes: attributes
            )
        }

        // Remove the old window
        overlayManager?.hide()

        // Get the focused window element
        guard let focusedWindow = try await access.focusedWindow() else { return }

        // Create a new manager, set it up, and display it
        let manager = OverlayManager()
        await manager.setup(with: focusedWindow, actionableElements: concise)
        manager.show()

        // Save it so that we keep a strong reference to it
        self.overlayManager = manager
    }
}

#Preview {
    ContentView()
}
