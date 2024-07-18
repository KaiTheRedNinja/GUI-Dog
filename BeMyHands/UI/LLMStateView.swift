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
                    Section {
                        VStack {
                            ContentUnavailableView("Loading", systemImage: "checklist.unchecked")
                        }
                        .frame(height: size.width*3/4)
                    }
                case .working, .complete, .error:
                    Section("Steps") {
                        stepsSection
                    }

                    if case let .error(lLMCommunicationError) = state.overallState {
                        Section("Error") {
                            Text(lLMCommunicationError.description)
                        }
                    }
                }
            }
            .frame(height: size.width)
            .cornerRadius(10)
            .padding(10)
        }
        .frame(width: size.width, height: size.height)
        .animation(.default, value: state)
    }

    var stepsSection: some View {
        ForEach(state.steps, id: \.step) { step in
            HStack(spacing: 12) {
                Group {
                    switch step.state {
                    case .notReached:
                        Image(systemName: "circle")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.gray)
                    case .working:
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(.init(0.8)) // make it look the same size as the images
                    case .complete:
                        Image(systemName: "checkmark.circle")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.green)
                    case .error:
                        Image(systemName: "exclamationmark.triangle")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.red)
                    }
                }
                .frame(width: 25, height: 25)

                Text(step.step)
                    .font(.title2)

                Spacer()
            }
        }
    }
}

#Preview {
    LazyVGrid(columns: .init(repeating: .init(), count: 2)) {
        LLMStateView(
            state: .init(
                goal: "Non loaded goal",
                steps: []
            ),
            size: .init(width: 373, height: 373)
        )

        LLMStateView(
            state: .init(
                goal: "Working Goal",
                steps: (0..<5).map {
                    .init(
                        step: "Step \($0)",
                        state: (
                            $0 < 2 ? .complete :
                                $0 > 2 ? .notReached : .working(.init())
                        )
                    )
                },
                currentStepIndex: 2
            ),
            size: .init(width: 373, height: 373)
        )

        LLMStateView(
            state: .init(
                goal: "Completed goal",
                steps: (0..<5).map {
                    .init(
                        step: "Step \($0)",
                        state: .complete
                    )
                },
                currentStepIndex: 5
            ),
            size: .init(width: 373, height: 373)
        )

        LLMStateView(
            state: .init(
                goal: "Failed goal",
                steps: (0..<5).map {
                    .init(
                        step: "Step \($0)",
                        state: (
                            $0 < 4 ? .complete : .error(LLMCommunicationError.elementNotFound)
                        )
                    )
                },
                currentStepIndex: 5
            ),
            size: .init(width: 373, height: 373)
        )
    }
    .frame(width: 373*2, height: 373*2)
}
