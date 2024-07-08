//
//  OverlayManager.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import Foundation
import AppKit

class OverlayManager {
    let windowController: OverlayWindowController
    let framesController: FramesViewController

    init() {
        self.windowController = .init()
        self.framesController = .init()

//        guard let frame = NSScreen.main?.frame else {
//            fatalError("No screen frame found")
//        }

//        windowController.fitToFrame(frame)
        windowController.fitToFrame(.init(x: 10, y: 10, width: 500, height: 500))
        windowController.window?.contentViewController = framesController
    }

    func show() {
        windowController.showWindow(nil)
        windowController.window?.makeKeyAndOrderFront(nil)
    }
}
