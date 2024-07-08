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
            let elements = try await access.actionableElements()
            guard var elements else {
                print("No elements found")
                return
            }

            // Filter out so that only AXPress remains
            elements = elements.filter {
                ($0["actions"] as? [String])?.contains("AXPress") ?? false
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
            let concise = elements.compactMap { element in
                var data: [String: String] = [:]
                let attributes = element["attributes"] as! [String: Any]
                for item in items {
                    guard let attribute = attributes[item] else { continue }

                    if let attribute = (attributes[item] as? String), attribute.count > 0 {
                        data[item] = attribute
                    } else {
                        data[item] = "\(attribute)"
                    }
                }

                return data.count <= 1 ? nil : data
            }

            let data = try JSONSerialization.data(withJSONObject: concise, options: .prettyPrinted)
            guard let description = String(data: data, encoding: .utf8) else {
                print("Data is corrupted")
                return
            }
            print("Encoded: \(description)")
        } catch {
            print("ERROR: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
