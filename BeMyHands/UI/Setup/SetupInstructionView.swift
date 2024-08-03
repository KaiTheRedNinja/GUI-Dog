//
//  SetupInstructionView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 3/8/24.
//

import SwiftUI
import Luminare

struct SetupInstructionView: View {
    @Binding var stage: SetupStage

    var body: some View {
        VStack(spacing: 10) {
            Text("BeMyHands has been set up!")
                .font(.title)
                .bold()

            Text("To use BeMyHands, follow these steps:")

            Spacer()
                .frame(height: 20)

            VStack(alignment: .leading) {
                Text("1. Use your keyboard shortcut to open the instruction entry window")
                Text("2. Enter your instructions for BeMyHands")
                Text("3. Confirm your instructions by pressing return, or cancel by pressing escape")
                Text("4. Wait for BeMyHands to follow your instructions")
                Text("5. Use your keyboard shortcut again to interrupt BeMyHands")
            }
            .font(.title2)

            Spacer()
                .frame(height: 20)

            Button("Next") {
                stage = .warning
            }
            .frame(width: 150, height: 60)
            .buttonStyle(LuminareCompactButtonStyle())
            .foregroundStyle(Color.accentColor)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 30)
    }
}

#Preview {
    SetupInstructionView(stage: .constant(.instruction))
}
