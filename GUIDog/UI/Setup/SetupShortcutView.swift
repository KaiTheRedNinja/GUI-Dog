//
//  SetupShortcutView.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 30/7/24.
//

import SwiftUI
import Input

struct SetupShortcutView: View {
    @Binding var stage: SetupStage

    @State var keyboardShortcut: KeyBinding = PreferencesManager.global.keyboardShortcut

    var body: some View {
        VStack(spacing: 10) {
            Text("Set up the Keyboard Shortcut")
                .font(.title)
                .bold()

            Text(
"""
GUI Dog shows a spotlight-like text field when you press the keyboard shortcut. By default, it is \
control-option-command L.

You can customise the trigger shortcut here, if you wish to use a different one.
"""
            )
            .frame(width: 300)
            .font(.subheadline)

            Spacer()
                .frame(height: 30)

            Text("Click below to change the shortcut")
            ShortcutCaptureView(shortcut: $keyboardShortcut, large: true)
                .frame(height: 70)

            Spacer()
                .frame(height: 30)

            DogButton("Finish", color: .accentColor, action: confirm)
        }
        .multilineTextAlignment(.center)
    }

    func confirm() {
        stage.changeToNext()
        PreferencesManager.global.keyboardShortcut = keyboardShortcut
        PreferencesManager.global.save()
    }
}

#Preview {
    SetupShortcutView(stage: .constant(.setupShortcut))
}
