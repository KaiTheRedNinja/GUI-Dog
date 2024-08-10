//
//  DogButton.swift
//  GUI Dog
//
//  Created by Kai Quan Tay on 10/8/24.
//

import SwiftUI

struct DogButton: View {
    var title: String

    var color: Color

    var action: () -> Void

    init(_ title: String, color: Color = .gray, action: @escaping () -> Void) {
        self.title = title
        self.action = action
        self.color = color
    }

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .frame(width: 150, height: 60)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .opacity(0.5)
                        .shadow(radius: 5)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DogButton("Help") {}
}
