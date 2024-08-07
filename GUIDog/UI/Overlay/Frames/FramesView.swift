//
//  FramesView.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 16/7/24.
//

import Cocoa
import Access

class FramesView: NSView {
    func setupView(with frame: NSRect, actionableElements: [ActionableElement]) {
        self.subviews = []
        self.translatesAutoresizingMaskIntoConstraints = true
        self.frame = frame

        // Add subviews at the locations of every actionable element
        // Filter out items without frames, or with a frame of size zero
        for element in actionableElements where element.frame?.size != .zero {
            guard let elemFrame = element.frame else { continue }

            // elemFrame references items from the top-left of the screen, wheras system coordinates use bottom-left.
            // We need to convert them.

            let convertedFrame = NSRect(
                x: elemFrame.minX,
                y: frame.height - elemFrame.maxY,
                width: elemFrame.width,
                height: elemFrame.height
            )

            let elemView = NSView()
            elemView.translatesAutoresizingMaskIntoConstraints = true
            elemView.wantsLayer = true
            elemView.layer?.opacity = 0.2
            elemView.layer?.borderWidth = 1
            elemView.layer?.cornerRadius = 5
            elemView.layer?.borderColor = NSColor.windowBackgroundColor.cgColor
            elemView.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            elemView.toolTip = element.actions.joined(separator: ", ")
            elemView.frame = convertedFrame

            self.addSubview(elemView)
        }
    }
}
