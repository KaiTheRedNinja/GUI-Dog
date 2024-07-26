//
//  GoalsView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 21/7/24.
//

import SwiftUI

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
            .onAppear {
                textFieldFocus = true
            }
            .frame(width: size.width, height: size.height)
    }

    var content: some View {
        HStack {
            Image(systemName: "hand.wave")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .padding(.leading, 12)
                .padding(.trailing, 3)
            TextField("What would you like to do?", text: $text)
                .focused($textFieldFocus)
                .font(.title)
                .textFieldStyle(.plain)
                .onSubmit {
                    callback?(text)
                }
        }
    }
}

#Preview {
    GoalsView(size: .init(width: 600, height: 55))
}
