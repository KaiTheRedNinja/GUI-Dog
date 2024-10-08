//
//  GoalsView.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 21/7/24.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: #fileID, category: "GUIDog")

struct GoalsView: View {
    var size: NSSize
    var callback: ((String) -> Void)?

    @State private var text: String = ""
    @FocusState private var textFieldFocus: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: size.height/3)
            .fill(.regularMaterial)
            .overlay {
                content
            }
            .frame(width: size.width, height: size.height)
            .onAppear {
                // focus text field on appear
                textFieldFocus = true
            }
            .onDisappear {
                // trigger empty callback on disappear
                callback?("")
            }
            .onKeyPress(.escape) {
                // trigger empty callback when escape pressed
                callback?("")
                return .handled
            }
    }

    var content: some View {
        HStack {
            Image(systemName: "pawprint.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .padding(.leading, 15)
                .padding(.trailing, 4)
            TextField("What would you like to do?", text: $text)
                .focused($textFieldFocus)
                .font(.title)
                .textFieldStyle(.plain)
                .onSubmit {
                    callback?(text)
                    textFieldFocus = false
                }
        }
    }
}

#Preview {
    GoalsView(size: .init(width: 600, height: 55))
}
