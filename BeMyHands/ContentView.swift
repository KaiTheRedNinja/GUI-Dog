//
//  ContentView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import SwiftUI
import Access

struct ContentView: View {
    @State var access: Access?

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            if access != nil {
                Button("Test") {
                    Task {
                        await accessInfo()
                    }
                }
            }
        }
        .padding()
        .task {
            print("Setting up access")
            guard await Access() != nil else {
                print("Could not create access: Exiting")
                exit(0)
            }
        }
    }

    func accessInfo() async {
        guard let access else { return }
        await access.dumpApplication()
    }
}

#Preview {
    ContentView()
}
