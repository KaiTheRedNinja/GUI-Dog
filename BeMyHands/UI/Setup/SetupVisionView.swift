//
//  SetupVisionView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 27/7/24.
//

import SwiftUI
import Luminare

struct SetupVisionView: View {
    @Binding var stage: SetupStage

    @State var userVisionStatus: UserVisionStatus = PreferencesManager.global.userVisionStatus ?? .sighted

    var body: some View {
        VStack(spacing: 10) {
            Text("Are you visually impaired?")
                .font(.title)
                .bold()

            Text(
"""
BeMyHands is built for the visually impaired, to automate simple actions \
that are tedious to do with accessibility tech

Selecting "impaired" or "blind" will activate audio cues.
"""
            )
            .frame(width: 300)
            .font(.caption)

            Spacer()
                .frame(height: 30)

            LuminarePicker(elements: UserVisionStatus.allCases, selection: $userVisionStatus) { status in
                VStack {
                    Image(systemName: status.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundStyle(status.color)
                    Text(status.description)
                }
                .frame(height: 100)
            }
            .padding(.horizontal, 30)

            Spacer()
                .frame(height: 30)

            Button("Confirm") {
                confirm()
            }
            .frame(width: 150, height: 60)
            .buttonStyle(LuminareCompactButtonStyle())
        }
        .multilineTextAlignment(.center)
    }

    func confirm() {
        stage = .setupAccessManager
        PreferencesManager.global.userVisionStatus = userVisionStatus
        PreferencesManager.global.save()
    }
}

#Preview {
    SetupVisionView(stage: .constant(.blindOrNot))
}

extension UserVisionStatus {
    var icon: String {
        switch self {
        case .sighted: "eye"
        case .mildlyImpaired: "eyeglasses"
        case .impaired: "eye.trianglebadge.exclamationmark"
        case .blind: "eye.slash"
        }
    }

    var color: Color {
        switch self {
        case .sighted: .blue
        case .mildlyImpaired: .green
        case .impaired: .orange
        case .blind: .indigo
        }
    }
}
