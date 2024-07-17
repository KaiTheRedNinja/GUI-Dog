//
//  LLMStateView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 16/7/24.
//

import SwiftUI

struct LLMStateView: View {
    var state: LLMState
    var size: NSSize

    var body: some View {
        VStack {
            Spacer()
            List {
                Section {
                    Text(state.goal)
                        .font(.title)
                }

                switch state.commState {
                case .loading:
                    Text("Loading...")
                case .step(let actionStepContext):
                    Section("Steps") {
                        stepsSection(stepContext: actionStepContext)
                    }
                case .complete:
                    Text("Done!")
                case .error(let lLMCommunicationError):
                    Text("Error: \(lLMCommunicationError.localizedDescription)")
                }
            }
            .frame(height: size.width)
            .cornerRadius(10)
            .padding(10)
        }
        .frame(width: size.width, height: size.height)
        .animation(.default, value: state)
    }

    func stepsSection(stepContext: ActionStepContext) -> some View {
        ForEach(Array(state.steps.enumerated()), id: \.offset) { (index, step) in
            HStack {
                Group {
                    if index == stepContext.currentStep {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        let isBefore = index < stepContext.currentStep
                        Image(systemName: isBefore ? "checkmark.circle" : "circle")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(isBefore ? Color.green : .gray)
                    }
                }
                .frame(width: 30, height: 30)

                Text(step)

                Spacer()
            }
        }
    }
}

#Preview {
    LLMStateView(
        state: .init(
            goal: "Random Goal",
            steps: (0..<5).map { "Step \($0)" },
            commState: .step(
                .init(
                    currentStep: 2
                )
            )
        ),
        size: .init(width: 373, height: 373)
    )
}
