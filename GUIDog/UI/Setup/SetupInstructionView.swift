//
//  SetupInstructionView.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 3/8/24.
//

import SwiftUI

struct SetupInstructionView: View {
    @Binding var stage: SetupStage

    var body: some View {
        VStack(spacing: 10) {
            Text("GUI Dog has been set up!")
                .font(.title)
                .bold()

            Text("To use GUI Dog, follow these steps:")

            Spacer()
                .frame(height: 20)

            VStack(alignment: .leading) {
                Text("1. Use your keyboard shortcut to open the instruction entry window")
                Text("2. Enter your instructions for GUI Dog")
                Text("3. Confirm your instructions by pressing return, or cancel by pressing escape")
                Text("4. Wait for GUI Dog to follow your instructions")
                Text("5. Use your keyboard shortcut again to interrupt GUI Dog")
            }
            .font(.title2)

            Spacer()
                .frame(height: 20)

            DogButton("Next", color: .accentColor) {
                stage.changeToNext()
            }
        }
        .multilineTextAlignment(.center)
        .padding(.top, 30)
    }
}

#Preview {
    SetupInstructionView(stage: .constant(.instruction))
}
