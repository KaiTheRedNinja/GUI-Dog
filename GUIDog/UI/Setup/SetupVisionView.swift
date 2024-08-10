//
//  SetupVisionView.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 27/7/24.
//

import SwiftUI

struct SetupVisionView: View {
    @Binding var stage: SetupStage

    @State var userVisionStatus: UserVisionStatus = PreferencesManager.global.userVisionStatus

    var body: some View {
        VStack(spacing: 10) {
            Text("Are you visually impaired?")
                .font(.title)
                .bold()

            Text(
"""
GUI Dog is built for the visually impaired, to automate simple actions \
that are tedious to do with accessibility tech

Selecting "impaired" or "blind" will activate audio cues.
"""
            )
            .frame(width: 300)
            .font(.subheadline)

            Spacer()
                .frame(height: 30)

            HStack {
                ForEach(UserVisionStatus.allCases, id: \.hashValue) { status in
                    Button {
                        userVisionStatus = status
                    } label: {
                        VStack {
                            Image(systemName: status.icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundStyle(status.color)
                            Text(status.description)
                        }
                        .frame(width: 100, height: 100)
                        .background {
                            if userVisionStatus == status {
                                Color.accentColor
                                    .opacity(0.4)
                                    .cornerRadius(8)
                            } else {
                                Color.gray.opacity(0.2)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 30)

            Spacer()
                .frame(height: 30)

            DogButton("Confirm", color: .accentColor) {
                confirm()
            }
        }
        .multilineTextAlignment(.center)
    }

    func confirm() {
        stage.changeToNext()
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
