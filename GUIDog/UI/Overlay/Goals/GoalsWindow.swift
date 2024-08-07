//
//  GoalsWindow.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 8/7/24.
//

import Cocoa

/// Wraps a ``GoalsWindow``
class GoalsWindowController: NSWindowController {
    var windowDelegate: GoalsWindowDelegate = .init()

    init() {
        super.init(window: GoalsWindow())
        self.window?.delegate = windowDelegate
        windowDelegate.window = self.window as? GoalsWindow
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}

/// A window used to show the goal. Present above all windows, doesn't steal focus.
class GoalsWindow: NSPanel {
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

class GoalsWindowDelegate: NSObject, NSWindowDelegate {
    weak var window: GoalsWindow?

    func windowDidResignKey(_ notification: Notification) {
        close()
    }

    func windowDidResignMain(_ notification: Notification) {
        close()
    }

    func close() {
        window?.close()
        if let goalVC = window?.contentViewController as? GoalViewController {
            // trigger the callback
            goalVC.goalsView.rootView.callback?("")
        }
    }
}
