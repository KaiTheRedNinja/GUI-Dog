//
//  SetupWarningView.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 27/7/24.
//

import SwiftUI
import Luminare

struct SetupWarningView: View {
    @Binding var stage: SetupStage

    @Environment(\.dismissWindow)
    private var dismissWindow

    var body: some View {
        VStack(spacing: 10) {
            Text("GUI Dog has been set up!")
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
GUI Dog is intended to help the visually impaired execute actions that are tedious to do with \
a screen reader. Instructions must provide both *what* to do, and *how/where* to do it. Each \
instruction should be one task, which can be accomplished in one or two steps.

GUI Dog will not be able to satisfy vague or complex instructions.
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
                title: "Clear Instructions",
                icon: "checkmark.circle",
                color: .green,
                subtitle: "Simple, clear, 1-2 step action",
                emoji: "✅",
                examples: [
                    "Open my Holidays folder in Downloads",
                    "Mark my Buy Tissue reminder as done in Reminders",
                    "Open Contacts app and call Bobby Smith"
                ]
            )

            instructionsView(
                title: "Vague Instructions",
                icon: "xmark.circle",
                color: .red,
                subtitle: "Vague, complex, or requires outside information",
                emoji: "❌",
                examples: [
                    "Open my Holidays folder",
                    "I have bought tissues, mark it as done",
                    "Call Bob"
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
            .accessibilityRepresentation {
                Text(title)
            }

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
                        .accessibilityElement(children: .combine)
                        Spacer()
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(Text("Examples of \(title)"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaPadding(.vertical, 10)
                .safeAreaPadding(.horizontal, 8)
            }
            .multilineTextAlignment(.leading)
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    SetupWarningView(stage: .constant(.warning))
}
