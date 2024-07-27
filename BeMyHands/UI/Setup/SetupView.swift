//
//  SetupView.swift
//  BeMyHands
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
        VStack {
            switch stage {
            case .home:
                SetupHomeView(stage: $stage)
            case .blindOrNot:
                SetupVisionView(stage: $stage)
            case .setupAccessManager:
                SetupAccessView(stage: $stage)
            case .finish:
                SetupFinishView(stage: $stage)
            }

            if stage != .home {
                Spacer()
                    .frame(height: 30)

                Button("Previous Page") {
                    stage = .home
                }
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
        .frame(width: 720, height: 500)
        .animation(.default, value: stage)
    }
}

enum SetupStage {
    case home
    case blindOrNot
    case setupAccessManager
    case finish
}

enum UserVisionStatus {
    case sighted
    case blind
}

#Preview {
    SetupView(setupCallback: {})
}
