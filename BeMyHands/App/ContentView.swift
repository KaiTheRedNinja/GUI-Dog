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
    @State var overlayManager: OverlayManager = OverlayManager()

    @State var updatingView: Bool = false

    var timer = Timer.publish(every: 2, on: .main, in: .default).autoconnect()

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            if access != nil {
                Toggle(isOn: $updatingView) {
                    Text("Update positions (currently every 2 seconds)")
                }
                .onReceive(timer) { _ in
                    Task {
                        try await overlayActionsOnCurrentWindow()
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

            // Show the overlay
            overlayManager.show()
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

        // Get the focused window element
        guard let focusedWindow = try await access.focusedWindow() else { return }

        // Update the manager
        await overlayManager.update(with: focusedWindow, actionableElements: concise)
    }
}

#Preview {
    ContentView()
}
