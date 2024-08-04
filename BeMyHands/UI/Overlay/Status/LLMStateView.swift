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
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Spacer()

                pillBackground(
                    text: state.goal,
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

                if state.overallState == .complete {
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
        .opacity(isShown ? 1 : 0)
        .frame(width: size.width, height: size.height)
        .animation(.default, value: state)
        .animation(.default, value: isShown)
    }

    var stepsSection: some View {
        ForEach(Array(state.steps.enumerated()), id: \.1.step) { (index, step) in
            pillBackground(
                text: step.step
            ) {
                if index+1 == state.steps.count { // must be current step
                    switch state.overallState {
                    case .cancelled, .error:
                        mute(color: Color.red)
                    default:
                        Color(nsColor: .windowBackgroundColor)
                    }
                } else {
                    Color(nsColor: .windowBackgroundColor)
                }
            } icon: {
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
        }
    }

    func pillBackground<B: View, I: View>(
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

    func mute(color: Color) -> some View {
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
            state: .init(
                goal: "Non loaded goal",
                steps: []
            ),
            size: frame,
            isShown: true
        )
        .frame(width: frame.width, height: frame.height)

        LLMStateView(
            state: .init(
                goal: "Working Goal",
                steps: steps,
                overallState: .working
            ),
            size: frame,
            isShown: true
        )
        .frame(width: frame.width, height: frame.height)

        LLMStateView(
            state: .init(
                goal: "Completed Goal",
                steps: steps,
                overallState: .complete
            ),
            size: frame,
            isShown: true
        )
        .frame(width: frame.width, height: frame.height)

        LLMStateView(
            state: .init(
                goal: "Failed goal",
                steps: steps,
                overallState: .error(.emptyResponse)
            ),
            size: frame,
            isShown: true
        )
        .frame(width: frame.width, height: frame.height)
    }
    .frame(width: 373*2, height: 373*2)
}
