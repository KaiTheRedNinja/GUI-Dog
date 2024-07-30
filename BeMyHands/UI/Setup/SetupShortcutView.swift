//
//  SetupShortcutView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 30/7/24.
//

import SwiftUI
import Luminare
import Input

struct SetupShortcutView: View {
    @Binding var stage: SetupStage

    @State var keyboardShortcut: KeyBinding = PreferencesManager.global.keyboardShortcut ?? .init(
        browseMode: true,
        controlModifier: true,
        optionModifier: true,
        commandModifier: true,
        key: .keyboardL
    )

    var body: some View {
        VStack(spacing: 10) {
            Text("Set up the Keyboard Shortcut")
                .font(.title)
                .bold()

            Text(
"""
BeMyHands shows a spotlight-like text field when you press the keyboard shortcut. By default, it is \
control-option-command L.

You can customise the trigger shortcut here, if you wish to use a different one.
"""
            )
            .frame(width: 300)
            .font(.subheadline)

            Spacer()
                .frame(height: 30)

            Text("Click below to change the shortcut")
            ShortcutCaptureView(shortcut: $keyboardShortcut)

            Spacer()
                .frame(height: 30)

            Button("Finish") {
                confirm()
            }
            .frame(width: 150, height: 60)
            .buttonStyle(LuminareCompactButtonStyle())
            .foregroundStyle(Color.accentColor)
        }
        .multilineTextAlignment(.center)
    }

    func confirm() {
        stage = .finish
        PreferencesManager.global.keyboardShortcut = keyboardShortcut
        PreferencesManager.global.save()
    }
}

struct ShortcutCaptureView: View {
    @Binding var shortcut: KeyBinding

    @State var changingShortcut: Bool = false

    var body: some View {
        HStack {
            if shortcut.commandModifier { shortcutComponentView(symbol: "command") }
            if shortcut.optionModifier { shortcutComponentView(symbol: "option") }
            if shortcut.controlModifier { shortcutComponentView(symbol: "control") }
            if shortcut.shiftModifier { shortcutComponentView(symbol: "shift") }

            if let symbol = shortcut.key.symbol {
                shortcutComponentView(symbol: symbol)
            } else if let short = shortcut.key.shortRepresentation {
                shortcutComponentView(text: short)
            } else {
                shortcutComponentView(text: shortcut.key.description)
            }
        }
        .padding(10)
        .overlay {
            Button {
                changeShortcut()
            } label: {
                Spacer()
            }
            .accessibilityLabel("Change Shortcut")
            .buttonStyle(LuminareCompactButtonStyle())
            .foregroundStyle(changingShortcut ? Color.accentColor : Color.gray)
            .disabled(changingShortcut)
        }
        .accessibilityRepresentation {
            Button(
                String.build {
                    if shortcut.commandModifier { "command" }
                    if shortcut.optionModifier { "option" }
                    if shortcut.controlModifier { "control" }
                    if shortcut.shiftModifier { "shift" }
                    shortcut.key.description

                    "Click this button to change the shortcut. Enter your new shortcut after pressing this button."
                }
            ) {
                changeShortcut()
            }
        }
    }

    func shortcutComponentView(symbol: String) -> some View {
        GroupBox {
            Image(systemName: symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(10)
        }
    }

    func shortcutComponentView(text: String) -> some View {
        Text(text)
            .font(.system(size: 100))
            .minimumScaleFactor(0.1)
            .frame(height: 60)
            .padding(.horizontal, 15)
    }

    func changeShortcut() {
        changingShortcut = true
        Input.shared.detectKeyEvent { newShortcut in
            changingShortcut = false
            guard newShortcut.commandModifier || newShortcut.controlModifier || newShortcut.optionModifier else {
                // shortcut needs at least one modifier
                return
            }
            shortcut = newShortcut
        }
    }
}

#Preview {
    SetupShortcutView(stage: .constant(.setupShortcut))
}
