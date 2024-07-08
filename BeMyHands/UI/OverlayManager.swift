//
//  OverlayManager.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import AppKit
import Element

class OverlayManager {
    var windowController: OverlayWindowController!
    var framesController: FramesViewController!
    var actionableElements: [ActionableElement]!

    init(windowController: OverlayWindowController! = nil, framesController: FramesViewController! = nil) {
        self.windowController = windowController
        self.framesController = framesController
    }

    @ElementActor
    func setup(with windowElement: Element, actionableElements: [ActionableElement]) {
        guard let frame = try? windowElement.getAttribute(.frame) as? NSRect else {
            fatalError("Focused window has no frame")
        }

        guard let screenSize = NSScreen.main?.frame.size else {
            fatalError("Could not get screen size")
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.windowController = .init()
            self.framesController = .init(frame: .init(origin: .zero, size: screenSize), actionableElements: actionableElements)
            self.actionableElements = actionableElements

            print("Screen size: \(screenSize), frame origin: \(frame.origin)")

            windowController.window?.setFrameOrigin(.init(x: 0, y: 0))
            windowController.window?.contentViewController = framesController
        }
    }

    func show() {
        windowController.showWindow(nil)
        windowController.window?.makeKeyAndOrderFront(nil)
        windowController.window?.orderFrontRegardless()
    }

    func hide() {
        windowController.window?.close()
    }
}
