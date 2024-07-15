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

    var body: some View {
        Group {
            if manager.accessAvailable {
                Button("Force Update") {
                    Task {
                        try await manager.takeAccessSnapshot()
                    }
                }
                Button("Request LLM") {
                    Task {
                        try await manager.takeAccessSnapshot()
                        try await manager.requestLLMAction(goal: "Open my applications folder")
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
