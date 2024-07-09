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
    @State var manager: AccessManager

    @State var updatingView: Bool = true

    var timer = Timer.publish(every: 2, on: .main, in: .default).autoconnect()

    var body: some View {
        Group {
            if manager.accessAvailable {
                Toggle(isOn: $updatingView) {
                    Text("Update positions (currently every 2 seconds)")
                }
                .onReceive(timer) { _ in
                    guard updatingView else { return }
                    Task {
                        try await manager.refreshActionableItems()
                    }
                }
            } else {
                Text("Setting up...")
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
