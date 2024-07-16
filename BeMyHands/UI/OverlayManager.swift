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
    private var framesController: FramesViewController

    private var outlinesVisible: Bool = true

    init() {
        self.windowController = .init()
        self.framesController = .init()
        windowController.window?.contentViewController = framesController
    }

    func update(with windowElement: Element, actionableElements: [ActionableElement]) async {
        // Obtain the frame of the window element. Currently not used, since we cover the entire screen.
        /*
        let frameTask = Task { @ElementActor in
            return try? windowElement.getAttribute(.frame) as? NSRect
        }

        guard let frame = await frameTask.value else {
            fatalError("Focused window has no frame")
        }
         */

        // Obtain the size of the screen
        guard let screenSize = NSScreen.main?.frame.size else {
            fatalError("Could not get screen size")
        }

        // Set up the size and position of the frames controller
        self.framesController.setupView(
            with: .init(origin: .zero, size: screenSize),
            actionableElements: actionableElements
        )
        windowController.window?.setFrameOrigin(.init(x: 0, y: 0))
    }

    func show() {
        windowController.showWindow(nil)
        windowController.window?.makeKeyAndOrderFront(nil)
        windowController.window?.orderFrontRegardless()
    }

    func hide() {
        windowController.window?.close()
    }

    func toggleOutlines() {
        outlinesVisible.toggle()
        framesController.view.isHidden = !outlinesVisible
    }
}
