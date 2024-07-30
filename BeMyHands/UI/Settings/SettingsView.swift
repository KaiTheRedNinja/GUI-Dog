//
//  SettingsView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 30/7/24.
//

import SwiftUI
import Luminare
import Input

struct SettingsView: View {
    @State var userVisionStatus: UserVisionStatus = PreferencesManager.global.userVisionStatus
    @State var keyboardShortcut: KeyBinding = PreferencesManager.global.keyboardShortcut

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                LuminareSection("User Vision Status") {
                    VStack(alignment: .leading) {
                        LuminarePicker(elements: UserVisionStatus.allCases, selection: $userVisionStatus) { status in
                            VStack {
                                Image(systemName: status.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(status.color)
                                Text(status.description)
                            }
                        }

                        visionStatusText
                            .padding(.horizontal, 8)
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
                    .padding(.horizontal, 8)
                }

                LuminareSection("Keyboard Shortcut") {
                    HStack {
                        Text("Click to change the shortcut")

                        Spacer()

                        ShortcutCaptureView(shortcut: $keyboardShortcut)
                            .frame(height: 30)
                    }
                    .padding(.leading, 8)
                }
            }
            .padding(10)
        }
        .frame(width: 500, height: 300)
        .animation(.default, value: userVisionStatus)
        .animation(.default, value: keyboardShortcut)
        .onChange(of: userVisionStatus) { _, newValue in
            PreferencesManager.global.userVisionStatus = newValue
        }
        .onChange(of: keyboardShortcut) { oldValue, newValue in
            PreferencesManager.global.keyboardShortcut = newValue
            Input.shared.rebindKey(from: oldValue, to: newValue)
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
