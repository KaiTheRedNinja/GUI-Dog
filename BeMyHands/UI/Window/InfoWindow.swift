//
//  InfoWindow.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 20/7/24.
//

import Cocoa

/// Wraps a ``InfoWindow``
class InfoWindowController: NSWindowController {
    init() {
        super.init(window: InfoWindow())
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}

/// A window used to display information. Present on all spaces, above all windows,
/// invisible background, non-interactable.
class InfoWindow: NSPanel {
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
