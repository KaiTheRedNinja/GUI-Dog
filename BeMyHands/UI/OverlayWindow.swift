//
//  OverlayWindow.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import Cocoa

class OverlayWindow: NSPanel {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: NSZeroRect, styleMask: .nonactivatingPanel, backing: backingStoreType, defer: flag)
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.ignoresMouseEvents = true

        self.hasShadow = false

        self.level = .statusBar
        self.collectionBehavior = [.fullScreenAuxiliary]
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

    override func windowDidLoad() {
        super.windowDidLoad()
    }
}