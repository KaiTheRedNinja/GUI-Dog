//
//  ElementsListView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 9/7/24.
//

import SwiftUI
import Element

struct ElementsListView: View {
    var actionableElements: [ActionableElement]

    @State var currentHover: (String, String)?

    var body: some View {
        List { // NOTE: this list does not scroll
            ForEach(actionableElements, id: \.description) { elem in
                viewFor(element: elem)
            }
        }
    }

    func viewFor(element elem: ActionableElement) -> some View {
        GroupBox {
            VStack(alignment: .leading) {
                Text("\(elem.attributes)")
                    .lineLimit(3)

                HStack {
                    ForEach(elem.actions, id: \.self) { action in
                        Button(action) {
                            // Note that the button cannot actually be clicked
                        }
                        .onHover { state in
                            if state {
                                currentHover = (elem.description, action)

                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    guard let currentHover, currentHover == (elem.description, action) else { return }
                                    // TODO: execute the action
                                    print("Executing action \(action) of: \(elem.description)")

                                    Task {
                                        try await elem.element.performAction(action)
                                        print("Task succeeded!")
                                    }
                                }
                            } else {
                                currentHover = nil
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
