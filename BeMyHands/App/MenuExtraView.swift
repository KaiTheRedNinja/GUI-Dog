//
//  MenuExtraView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import SwiftUI
import Access
import KeyboardShortcuts
import OSLog

private let logger = Logger(subsystem: #file, category: "BeMyHands")

struct MenuExtraView: View {
    var triggerLLM: () -> Void

    var body: some View {
        Group {
            Button("Request LLM") {
                requestLLM()
            }
            .onAppear {
                KeyboardShortcuts.onKeyUp(for: .requestLLM) { [self] in
                    logger.info("Requesting LLM!")
                    requestLLM()
                }
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

extension KeyboardShortcuts.Name {
    static let requestLLM = Self("requestLLM", default: .init(.l, modifiers: [.command, .option]))
}
