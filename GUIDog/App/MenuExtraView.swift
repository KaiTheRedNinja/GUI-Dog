//
//  MenuExtraView.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 8/7/24.
//

import SwiftUI
import Access
import OSLog

private let logger = Logger(subsystem: #fileID, category: "GUIDog")

struct MenuExtraView: View {
    var triggerLLM: () -> Void

    @Environment(\.openWindow)
    var openWindow

    var body: some View {
        Group {
            Button("Request LLM") {
                requestLLM()
            }

            Divider()

            Button("Settings") {
                openWindow.callAsFunction(id: "settingsWindow")
            }
            .keyboardShortcut(",", modifiers: [.command])

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    func requestLLM() {
        triggerLLM()
    }
}
