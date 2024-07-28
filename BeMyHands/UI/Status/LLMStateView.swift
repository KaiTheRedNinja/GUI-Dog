//
//  LLMStateView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 16/7/24.
//

import SwiftUI
import HandsBot

struct LLMStateView: View {
    var state: LLMState
    var size: NSSize
    var isShown: Bool

    var body: some View {
        VStack {
            Spacer()
            List {
                Section {
                    Text(state.goal)
                        .font(.title)
                }

                switch state.overallState {
                case .checkingFeasibility:
                    Section {
                        VStack {
                            ContentUnavailableView("Loading", systemImage: "checklist.unchecked")
                        }
                        .frame(height: size.width*3/4)
                    }
                default:
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
            .shadow(radius: 10)
            .padding(10)
        }
        .opacity(isShown ? 1 : 0)
        .frame(width: size.width, height: size.height)
        .animation(.default, value: state)
        .animation(.default, value: isShown)
    }

    var stepsSection: some View {
        ForEach(Array(state.steps.enumerated()), id: \.1.step) { (index, step) in
            HStack(spacing: 12) {
                Group {
                    if index+1 == state.steps.count { // current step
                        switch state.overallState {
                        case .working: // current step in progress
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(.init(0.8)) // make it look the same size as the images
                        case .complete: // current step complete
                            Image(systemName: "checkmark.circle")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.green)
                        case .cancelled, .error: // issue with current step
                            Image(systemName: "exclamationmark.triangle")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.red)
                        default: // this should never occur
                            Image(systemName: "circle")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.gray)
                        }
                    } else {
                        Image(systemName: "checkmark.circle")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.green)
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

private struct ViewPreview: View {
    @State var shown: Bool = true

    var body: some View {
        VStack {
            LLMStateView(
                state: .init(
                    goal: "Working Goal",
                    steps: (0..<5).map {
                        .init(
                            step: "Step \($0)"
                        )
                    }
                ),
                size: .init(width: 373, height: 373),
                isShown: shown
            )
            Toggle("Shown?", isOn: $shown)
        }
    }
}

#Preview {
    ViewPreview()

    /*
    LazyVGrid(columns: .init(repeating: .init(), count: 2)) {
        LLMStateView(
            state: .init(
                goal: "Non loaded goal",
                steps: []
            ),
            size: .init(width: 373, height: 373),
            isShown: true
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
            size: .init(width: 373, height: 373),
            isShown: true
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
            size: .init(width: 373, height: 373),
            isShown: true
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
            size: .init(width: 373, height: 373),
            isShown: true
        )
    }
    .frame(width: 373*2, height: 373*2)
     */
}
