//
//  SetupAccessView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 27/7/24.
//

import SwiftUI

struct SetupAccessView: View {
    @Binding var stage: SetupStage

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    SetupAccessView(stage: .constant(.setupAccessManager))
}
