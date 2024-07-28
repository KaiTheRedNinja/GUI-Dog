//
//  SetupFinishView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 27/7/24.
//

import SwiftUI
import Luminare

struct SetupFinishView: View {
    @Binding var stage: SetupStage

    @Environment(\.dismissWindow)
    private var dismissWindow

    var body: some View {
        VStack(spacing: 10) {
            Text("BeMyHands has been set up!")
                .font(.title)
                .bold()

            Text("Before we start...")

            Spacer()
                .frame(height: 20)

            instructions
                .padding(.horizontal, 30)

            Spacer()
                .frame(height: 10)

            Text(
"""
BeMyHands is intended to help the visually impaired execute actions that are tedious to do with \
a screen reader, not to automate complex actions

BeMyHands will not be able to satisfy actions that are too complex, or require outside information.
"""
            )
            .frame(width: 600)

            Spacer()
                .frame(height: 10)

            Button("Close Setup") {
                dismissWindow.callAsFunction()
            }
            .frame(width: 150, height: 60)
            .buttonStyle(LuminareCompactButtonStyle())
            .foregroundStyle(Color.accentColor)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 30)
    }

    var instructions: some View {
        HStack {
            instructionsView(
                title: "Good Instructions",
                icon: "checkmark.circle",
                color: .green,
                subtitle: "Simple, clear, 1-2 step action",
                emoji: "✅",
                examples: [
                    "Open my Pictures folder in Downloads",
                    "Mark my Buy Tissue reminder as done in Reminders"
                ]
            )

            instructionsView(
                title: "Bad Instructions",
                icon: "xmark.circle",
                color: .red,
                subtitle: "Vague, complex, or requires outside information",
                emoji: "❌",
                examples: [
                    "Buy me a coffee",
                    "Mark my Buy Tissue reminder as done in Reminders"
                ]
            )
        }
    }

    // swiftlint:disable:next function_parameter_count
    func instructionsView(
        title: String,
        icon: String,
        color: Color,
        subtitle: String,
        emoji: String,
        examples: [String]
    ) -> some View {
        VStack {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
            }
            .font(.title2)
            .bold()

            Text(subtitle)
                .font(.caption)

            GroupBox {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(examples, id: \.self) { example in
                            HStack(alignment: .top) {
                                Text(emoji)
                                    .font(.title2)
                                Text(example)
                                    .font(.title3)
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaPadding(.vertical, 10)
                .safeAreaPadding(.horizontal, 8)
            }
            .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    SetupFinishView(stage: .constant(.finish))
}
