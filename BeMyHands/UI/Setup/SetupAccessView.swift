//
//  SetupAccessView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 27/7/24.
//

import SwiftUI
import Luminare
import Element
import OSLog

private let logger = Logger(subsystem: #fileID, category: "BeMyHands")

struct SetupAccessView: View {
    @Binding var stage: SetupStage

    @State var permissionGranted = false

    var setupCallback: () -> Void

    /// Timer that repeats every second
    var timer = Timer.publish(every: 1, on: .main, in: .default).autoconnect()

    var body: some View {
        VStack(spacing: 10) {
            Text("Please grant BeMyHands\nAccessibility permission")
                .font(.title)
                .bold()

            Text(
"""
BeMyHands uses macOS's Accessibility API to interact with items on your screen.
"""
            )
            .frame(width: 300)
            .font(.caption)
            .multilineTextAlignment(.center)

            Spacer()
                .frame(height: 30)

            VStack(alignment: .leading) {
                Text("1. Go to Privacy and Security in System Preferences")
                Text("2. Open the Accessibility tab")
                Text("3. Switch on the toggle for BeMyHands")
            }
            .opacity(permissionGranted ? 0.5 : 1)
            .font(.title2)

            Spacer()
                .frame(height: 30)

            HStack {
                Button("Request permission") {
                    permissionGranted = Element.confirmProcessTrustedStatus()
                }
                .frame(width: 150, height: 60)
                .buttonStyle(LuminareCompactButtonStyle())

                Button("Finished!") {
                    stage = .finish
                }
                .frame(width: 150, height: 60)
                .buttonStyle(LuminareCompactButtonStyle())
                .foregroundStyle(Color.accentColor)
                .disabled(!permissionGranted)
            }
        }
        .onReceive(timer) { _ in
            permissionGranted = Element.checkProcessTrustedStatus()
        }
        .onAppear {
            permissionGranted = Element.checkProcessTrustedStatus()
        }
        .onChange(of: permissionGranted) { _, _ in
            setupCallback()
        }
    }
}

#Preview {
    SetupAccessView(stage: .constant(.setupAccessManager), setupCallback: {})
}
