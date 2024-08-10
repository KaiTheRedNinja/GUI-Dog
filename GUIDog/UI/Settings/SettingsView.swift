//
//  SettingsView.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 30/7/24.
//

import SwiftUI
import Input

struct SettingsView: View {
    @State var userVisionStatus: UserVisionStatus = PreferencesManager.global.userVisionStatus
    @State var keyboardShortcut: KeyBinding = PreferencesManager.global.keyboardShortcut

    var body: some View {
        List {
            Section("User Vision Status") {
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

                HStack {
                    if userVisionStatus.useAudioCues {
                        Image(systemName: "speaker.wave.2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(Color.green)
                        Text("Audio cues are enabled for impaired and blind users.")
                    } else {
                        Image(systemName: "speaker.slash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(Color.gray)
                        Text("Audio cues are disabled for sighted and mildly impaired users.")
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }

            Section("Keyboard Shortcut") {
                HStack {
                    Text("Click to change the shortcut")

                    Spacer()

                    ShortcutCaptureView(shortcut: $keyboardShortcut)
                        .frame(height: 30)
                }
            }
        }
        .frame(width: 500, height: 300)
        .animation(.default, value: userVisionStatus)
        .animation(.default, value: keyboardShortcut)
        .onChange(of: userVisionStatus) { _, newValue in
            PreferencesManager.global.userVisionStatus = newValue
        }
        .onChange(of: keyboardShortcut) { _, newValue in
            PreferencesManager.global.keyboardShortcut = newValue
        }
    }

    var visionStatusText: some View {
        switch userVisionStatus {
        case .sighted:
            Text("You have full vision.")
        case .mildlyImpaired:
            Text("Your vision is slightly impaired, but close to full vision with glasses or contact lenses.")
        case .impaired:
            Text("Your vision is severely impaired, even with glasses or contact lenses.")
        case .blind:
            Text("You are completely blind, and you need to use a screen reader or other assistive technology.")
        }
    }
}

#Preview {
    SettingsView()
}
