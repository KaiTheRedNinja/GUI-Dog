//
//  LLMStateView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 16/7/24.
//

import SwiftUI
import HandsBot
import OSLog

private let logger = Logger(subsystem: #fileID, category: "BeMyHands")

class LLMStateObject: ObservableObject {
    @Published var state: LLMState = .zero
    @Published var isShown: Bool = false
    @Published var size: NSSize = .init(width: 300, height: 300)

    init(state: LLMState, isShown: Bool, size: NSSize) {
        self.state = state
        self.isShown = isShown
        self.size = size
    }
}

struct LLMStateView: View {
    @ObservedObject var stateObject: LLMStateObject

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Spacer()

                pillBackground(
                    text: stateObject.state.goal,
                    backgroundColor: {
                        Color(nsColor: .windowBackgroundColor)
                    },
                    icon: {
                        Image(systemName: "flag.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(Color.accentColor)
                    }
                )

                stepsSection

                if stateObject.state.overallState == .complete {
                    pillBackground(
                        text: "Done!",
                        backgroundColor: {
                            mute(color: .green)
                        },
                        icon: {
                            Image(systemName: "flag.pattern.checkered")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(Color.green)
                        }
                    )
                }
            }
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.3), radius: 6)
            .padding(15)
        }
        .defaultScrollAnchor(.bottom)
        .opacity(stateObject.isShown ? 1 : 0)
        .frame(width: stateObject.size.width, height: stateObject.size.height)
        .animation(.default, value: stateObject.state)
        .animation(.default, value: stateObject.isShown)
    }

    private var stepsSection: some View {
        ForEach(Array(stateObject.state.steps.enumerated()), id: \.1.step) { (index, step) in
            pillBackground(
                text: step.step
            ) {
                if index+1 == stateObject.state.steps.count { // must be current step
                    switch stateObject.state.overallState {
                    case .cancelled, .error:
                        mute(color: Color.red)
                    default:
                        Color(nsColor: .windowBackgroundColor)
                    }
                } else {
                    Color(nsColor: .windowBackgroundColor)
                }
            } icon: {
                if index+1 == stateObject.state.steps.count { // current step
                    switch stateObject.state.overallState {
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
        }
    }

    private func pillBackground<B: View, I: View>(
        text: String,
        @ViewBuilder backgroundColor: () -> B,
        @ViewBuilder icon: () -> I
    ) -> some View {
        HStack {
            icon()
                .frame(width: 20, height: 20)
                .padding(.trailing, 3)
            Text(text)
                .font(.title2)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(15)
        .background {
            backgroundColor()
                .mask {
                    RoundedRectangle(cornerRadius: 18)
                }
        }
    }

    private func mute(color: Color) -> some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            color
                .opacity(0.2)
        }
    }
}

#Preview {
    LazyVGrid(columns: .init(repeating: .init(), count: 2)) {
        let frame = CGSize(width: 373, height: 373)

        let steps: [LLMStep] = (0..<6).map {
            .init(step: "Step \($0)")
        }

        LLMStateView(
            stateObject: .init(
                state: .init(
                    goal: "Non loaded goal",
                    steps: []
                ),
                isShown: true,
                size: frame
            )
        )
        .frame(width: frame.width, height: frame.height)

        LLMStateView(
            stateObject: .init(
            state: .init(
                goal: "Working Goal",
                steps: steps,
                overallState: .working
            ),
            isShown: true,
            size: frame
            )
        )
        .frame(width: frame.width, height: frame.height)

        LLMStateView(
            stateObject: .init(
            state: .init(
                goal: "Completed Goal",
                steps: steps,
                overallState: .complete
            ),
            isShown: true,
            size: frame
            )
        )
        .frame(width: frame.width, height: frame.height)

        LLMStateView(
            stateObject: .init(
            state: .init(
                goal: "Failed goal",
                steps: steps,
                overallState: .error(.emptyResponse)
            ),
            isShown: true,
            size: frame
            )
        )
        .frame(width: frame.width, height: frame.height)
    }
    .frame(width: 373*2, height: 373*2)
}
