//
//  ContentView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import SwiftUI
import Access
import KeyboardShortcuts

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
                    requestLLM()
                }
                .onAppear {
                    KeyboardShortcuts.onKeyUp(for: .requestLLM) { [self] in
                        print("Requesting LLM!")
                        requestLLM()
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

    func requestLLM() {
        Task {
            try await manager.takeAccessSnapshot()
            try await manager.requestLLMAction(goal: "Open my CS50 folder in the documents directory")
        }
    }
}

extension KeyboardShortcuts.Name {
    static let requestLLM = Self("requestLLM", default: .init(.l, modifiers: [.command, .option]))
}
