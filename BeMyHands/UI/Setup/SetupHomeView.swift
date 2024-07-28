//
//  SetupHomeView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 27/7/24.
//

import SwiftUI
import Luminare

struct SetupHomeView: View {
    @Binding var stage: SetupStage

    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSImage(named: "AppIcon")!)
                .resizable()
                .scaledToFit()
                .padding()
                .frame(width: 200, height: 200)

            Text("Welcome to BeMyHands")
                .font(.title)
                .bold()

            Spacer()
                .frame(height: 20)

            Button("Lets Go!") {
                stage = .blindOrNot
            }
            .frame(width: 150, height: 60)
            .buttonStyle(LuminareCompactButtonStyle())
            .foregroundStyle(Color.accentColor)
        }
    }
}

#Preview {
    SetupHomeView(stage: .constant(.home))
}
