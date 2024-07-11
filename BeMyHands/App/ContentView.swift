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
                        print("Forcing update...")
                        try await manager.takeAccessSnapshot()
                        print("Forced update")
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
