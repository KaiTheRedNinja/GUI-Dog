//
//  MenuExtraView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import SwiftUI
import Access
import OSLog

private let logger = Logger(subsystem: #fileID, category: "BeMyHands")

struct MenuExtraView: View {
    var triggerLLM: () -> Void

    var body: some View {
        Group {
            Button("Request LLM") {
                requestLLM()
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    func requestLLM() {
        triggerLLM()
    }
}
