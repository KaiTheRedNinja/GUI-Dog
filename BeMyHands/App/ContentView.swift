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
                Button("Test") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                        Task {
                            await accessInfo()
                        }
                    }
                }
                Button("Set up window") {
                    Task {
                        await setupWindow()
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

    func accessInfo() async {
        guard let access else { return }
        do {
            guard let elements = try await access.actionableElements() else {
                print("No elements found")
                return
            }

            // Filter out so that only AXPress remains
//            elements = elements.filter {
//                ($0["actions"] as? [String])?.contains("AXPress") ?? false
//            }

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

            print(concise.map { $0.description }.joined(separator: "\n"))
        } catch {
            print("ERROR: \(error)")
        }
    }

    func setupWindow() async {
        overlayManager?.hide()

        do {
            guard let focusedWindow = try await access?.focusedWindow() else { return }

            let manager = OverlayManager()

            await manager.setup(with: focusedWindow)

            manager.show()

            self.overlayManager = manager
        } catch {
            print("Error setting up window: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
