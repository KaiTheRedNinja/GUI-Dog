//
//  OverlayManager.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import AppKit
import Element
import HandsBot

@MainActor
class OverlayManager: LLMDisplayDelegate, AccessDisplayDelegate {
    private var framesWindowController: InfoWindowController
    private var framesController: FramesViewController

    private var statusWindowController: InfoWindowController
    private var statusController: StatusViewController

    init() {
        framesWindowController = .init()
        framesController = .init()
        statusWindowController = .init()
        statusController = .init()
        framesWindowController.window?.contentViewController = framesController
        statusWindowController.window?.contentViewController = statusController
    }

    func update(actionableElements: [ActionableElement]) async {
        // Obtain the size of the screen
        guard let screenSize = NSScreen.main?.frame.size else {
            fatalError("Could not get screen size")
        }

        // Set up the size and position of the frames controller
        self.framesController.setupFrames(
            with: .init(origin: .zero, size: screenSize),
            actionableElements: actionableElements
        )
        self.statusController.setupFrames(
            with: .init(origin: .zero, size: screenSize),
            actionableElements: actionableElements
        )
        framesWindowController.window?.setFrameOrigin(.init(x: 0, y: 0))
        statusWindowController.window?.setFrameOrigin(.init(x: 0, y: 0))
    }

    func update(state: LLMState) {
        self.framesController.setupState(with: state)
        self.statusController.setupState(with: state)
    }

    func show() {
        for windowController in [framesWindowController, statusWindowController] {
            windowController.showWindow(nil)
            windowController.window?.makeKeyAndOrderFront(nil)
            windowController.window?.orderFrontRegardless()
        }

        framesController.show()
        statusController.show()
    }

    func hide() {
        framesController.hide()
        statusController.hide()
    }
}
