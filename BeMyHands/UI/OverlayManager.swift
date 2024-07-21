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

    private var goalWindowController: ControlsWindowController
    private var goalController: GoalViewController

    init() {
        framesWindowController = .init()
        framesController = .init()
        statusWindowController = .init()
        statusController = .init()
        goalWindowController = .init()
        goalController = .init()
        framesWindowController.window?.contentViewController = framesController
        statusWindowController.window?.contentViewController = statusController
        goalWindowController.window?.contentViewController = goalController
    }

    func requestGoal() async -> String? {
        goalWindowController.showWindow(nil)
        goalWindowController.window?.makeKeyAndOrderFront(nil)
        goalWindowController.window?.orderFrontRegardless()
        goalController.show()

        let value = await withCheckedContinuation { cont in
            goalController.setCallback { value in
                cont.resume(returning: value)
            }
        }

        goalController.hide()

        if value.isEmpty {
            return nil
        } else {
            return value
        }
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
        framesWindowController.window?.setFrameOrigin(.init(x: 0, y: 0))
    }

    func update(state: LLMState) {
        // Obtain the size of the screen
        guard let screenSize = NSScreen.main?.frame.size else {
            fatalError("Could not get screen size")
        }

        self.statusController.setupFrames(
            with: .init(origin: .zero, size: screenSize)
        )
        self.statusController.setupState(with: state)
        statusWindowController.window?.setFrameOrigin(.init(x: 0, y: 0))
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
