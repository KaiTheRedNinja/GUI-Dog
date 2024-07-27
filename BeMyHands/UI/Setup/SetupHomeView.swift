//
//  SetupHomeView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 27/7/24.
//

import SwiftUI

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

            Button("Lets Go!") {
                stage = .blindOrNot
            }
        }
    }
}

#Preview {
    SetupHomeView(stage: .constant(.home))
}
