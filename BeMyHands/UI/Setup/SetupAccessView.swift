//
//  SetupAccessView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 27/7/24.
//

import SwiftUI
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

            Spacer()
                .frame(height: 30)

            VStack(alignment: .leading) {
                HStack {
                    Text("1. ")
                    Button("Request permission") {
                        permissionGranted = Element.confirmProcessTrustedStatus()
                    }
                }

                Text("2. Go to Privacy and Security in System Preferences")
                Text("2. Open the Accessibility tab")
                Text("3. Switch on the toggle for BeMyHands")
            }
            .foregroundStyle(permissionGranted ? .gray : .black)

            Spacer()
                .frame(height: 30)

            Button {
                stage = .finish
            } label: {
                Text("Finished!")
                    .padding(20)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor.opacity(0.7))
                    }
            }
            .buttonStyle(.plain)
            .disabled(!permissionGranted)
        }
        .onReceive(timer) { _ in
            logger.info("Checking if permission granted")
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
