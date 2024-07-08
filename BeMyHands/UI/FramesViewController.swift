//
//  FramesViewController.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import AppKit
import SwiftUI

class FramesViewController: NSViewController {
    var frame: NSRect

    init(frame: NSRect) {
        self.frame = frame
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = NSHostingView(rootView: Color.blue.opacity(0.5).frame(width: frame.width, height: frame.height))
    }
}
