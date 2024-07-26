//
//  ControlsWindow.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import Cocoa

/// Wraps a ``ControlsWindow``
class ControlsWindowController: NSWindowController {
    init() {
        super.init(window: ControlsWindow())
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}

/// A window used to show controls. Present above all windows, doesn't steal focus.
class ControlsWindow: NSPanel {
    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: NSRect.zero,
            styleMask: [
                .nonactivatingPanel,
                .resizable,
                .fullSizeContentView
            ],
            backing: backingStoreType,
            defer: flag
        )
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.level = .screenSaver
        self.collectionBehavior =  [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.isFloatingPanel = true
        self.isMovableByWindowBackground = true
    }

    override var canBecomeKey: Bool {
        return true
    }
}
