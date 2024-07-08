//
//  FramesViewController.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import AppKit
import SwiftUI

class FramesViewController: NSViewController {
    override func loadView() {
        self.view = NSHostingView(rootView: Color.blue.opacity(0.5).frame(width: 500, height: 500))
    }
}
