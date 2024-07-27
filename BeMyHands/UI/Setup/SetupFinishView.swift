//
//  SetupFinishView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 27/7/24.
//

import SwiftUI

struct SetupFinishView: View {
    @Binding var stage: SetupStage

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    SetupFinishView(stage: .constant(.finish))
}
