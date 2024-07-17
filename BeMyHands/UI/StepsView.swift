//
//  StepsView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 16/7/24.
//

import SwiftUI

struct StepsView: View {
    var stepContext: ActionStepContext?
    var size: NSSize

    var body: some View {
        VStack {
            Spacer()
            if let stepContext {
                List {
                    Section {
                        Text(stepContext.goal)
                            .font(.title)
                    }

                    Section("Steps") {
                        stepsSection(stepContext: stepContext)
                    }
                }
                .frame(height: size.width)
                .cornerRadius(10)
                .padding(10)
            }
        }
        .frame(width: size.width, height: size.height)
        .animation(.default, value: stepContext)
    }

    @ViewBuilder
    func stepsSection(stepContext: ActionStepContext) -> some View {
        if !stepContext.allSteps.isEmpty {
            ForEach(Array(stepContext.allSteps.enumerated()), id: \.offset) { (index, step) in
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
        } else {
            Text("Loading...")
        }
    }
}

#Preview {
    StepsView(
        stepContext: .init(
            goal: "Random Goal",
            allSteps: (0..<5).map { "Step \($0)" },
            currentStep: 2
        ),
        size: .init(width: 373, height: 373)
    )

    StepsView(
        stepContext: .init(
            goal: "Random Goal",
            allSteps: [],
            currentStep: 2
        ),
        size: .init(width: 373, height: 373)
    )
}
