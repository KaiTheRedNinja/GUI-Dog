//
//  OverlayManager.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import AppKit
import Element

@MainActor
class OverlayManager {
    private var windowController: OverlayWindowController
    private var contentController: ContentViewController

    init() {
        self.windowController = .init()
        self.contentController = .init()
        windowController.window?.contentViewController = contentController
    }

    func update(with windowElement: Element, actionableElements: [ActionableElement]) async {
        // Obtain the size of the screen
        guard let screenSize = NSScreen.main?.frame.size else {
            fatalError("Could not get screen size")
        }

        // Set up the size and position of the frames controller
        self.contentController.setupFrames(
            with: .init(origin: .zero, size: screenSize),
            actionableElements: actionableElements
        )
        windowController.window?.setFrameOrigin(.init(x: 0, y: 0))
    }

    func update(with state: LLMState) {
        self.contentController.setupState(with: state)
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
