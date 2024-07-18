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

                switch state.overallState {
                case .stepsNotLoaded:
                    Text("Loading...")
                case .working:
                    switch state.currentStep.state {
                    case .working(let stepContext):
                        Section("Steps") {
                            stepsSection(stepContext: stepContext)
                        }
                    default:
                        Text("Internal Inconsistency")
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
                    if index == state.currentStepIndex {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        let isBefore = index < state.currentStepIndex
                        Image(systemName: isBefore ? "checkmark.circle" : "circle")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(isBefore ? Color.green : .gray)
                    }
                }
                .frame(width: 30, height: 30)

                Text(step.step)

                Spacer()
            }
        }
    }
}

#Preview {
    LLMStateView(
        state: .init(
            goal: "Random Goal",
            steps: (0..<5).map {
                .init(
                    step: "Step \($0)",
                    state: (
                        $0 < 2 ? .complete :
                        $0 > 2 ? .notReached : .working(.init())
                    )
                )
            }
        ),
        size: .init(width: 373, height: 373)
    )
}
