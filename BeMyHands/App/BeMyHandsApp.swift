//
//  BeMyHandsApp.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import SwiftUI
import Access

@main
struct BeMyHandsApp: App {
    @State var accessManager: AccessManager!

    var body: some Scene {
        MenuBarExtra {
            if let accessManager {
                MenuExtraView(manager: accessManager)
            } else {
                Text("Something went wrong...")
            }
        } label: {
            Image(systemName: "hand.wave.fill")
                .task {
                    accessManager = .init()
                    await accessManager.setup()
                }
        }
    }
}
