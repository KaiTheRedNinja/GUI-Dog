//
//  SetupView.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 27/7/24.
//

import SwiftUI
import Element

struct SetupView: View {
    @Environment(\.dismissWindow)
    private var dismissWindow

    @State private var stage: SetupStage = .home

    /// Callback to set up the access manager
    private var setupCallback: () -> Void

    init(setupCallback: @escaping () -> Void) {
        self.setupCallback = setupCallback
    }

    var body: some View {
        ZStack {
            Color.clear
                .overlay(alignment: .topLeading) {
                    if stage != .home {
                        DogButton("Previous Page") {
                            stage = stage.previous()!
                        }
                        .padding(10)
                    }
                }

            switch stage {
            case .home:
                SetupHomeView(stage: $stage)
            case .blindOrNot:
                SetupVisionView(stage: $stage)
            case .setupAccessManager:
                SetupAccessView(stage: $stage, setupCallback: setupCallback)
            case .setupShortcut:
                SetupShortcutView(stage: $stage)
            case .instruction:
                SetupInstructionView(stage: $stage)
            case .warning:
                SetupWarningView(stage: $stage)
            }
        }
        .padding()
        .padding(.bottom, 30)
        .onAppear {
            // if process is already trusted, we can close this window
            if Element.checkProcessTrustedStatus() {
                dismissWindow()
            }
        }
        .frame(minWidth: 720, minHeight: 560)
        .animation(.default, value: stage)
    }
}

enum SetupStage: Int {
    case home
    case blindOrNot
    case setupAccessManager
    case setupShortcut
    case instruction
    case warning

    func next() -> SetupStage? {
        .init(rawValue: self.rawValue + 1)
    }

    func previous() -> SetupStage? {
        .init(rawValue: self.rawValue - 1)
    }

    mutating func changeToNext() {
        if let next = self.next() {
            self = next
        }
    }

    mutating func changeToPrevious() {
        if let previous = self.previous() {
            self = previous
        }
    }
}

#Preview {
    SetupView(setupCallback: {})
}
