//
//  OverlayWindow.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import Cocoa

class OverlayWindow: NSPanel {
    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(contentRect: NSRect.zero, styleMask: .nonactivatingPanel, backing: backingStoreType, defer: flag)
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.ignoresMouseEvents = true

        self.hasShadow = false

        self.level = .screenSaver
        self.collectionBehavior =  [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.isFloatingPanel = true
    }

    override var canBecomeKey: Bool {
        return true
    }
}

class OverlayWindowController: NSWindowController {

    init() {
        super.init(window: OverlayWindow())
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}
