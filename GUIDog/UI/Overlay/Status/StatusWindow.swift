//
//  StatusWindow.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 27/7/24.
//

import Cocoa

/// Wraps a ``StatusWindow``
class StatusWindowController: NSWindowController {
    init() {
        super.init(window: StatusWindow())
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}

/// A window used to display information. Present on all spaces, above all windows,
/// invisible background, non-interactable.
class StatusWindow: NSPanel {
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
