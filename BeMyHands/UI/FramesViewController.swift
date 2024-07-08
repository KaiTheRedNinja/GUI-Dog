//
//  FramesViewController.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import AppKit
import SwiftUI
import Element

class FramesViewController: NSViewController {
    var frame: NSRect
    var actionableElements: [ActionableElement]

    init(frame: NSRect, actionableElements: [ActionableElement]) {
        self.frame = frame
        self.actionableElements = actionableElements
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.wantsLayer = true
        view.layer?.backgroundColor = .init(gray: 0.5, alpha: 0.5)
        view.frame = frame

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
            elemView.layer?.backgroundColor = .init(red: 1, green: 0, blue: 0, alpha: 0.5)
            elemView.frame = convertedFrame

            view.addSubview(elemView)
        }

        self.view = view
    }
}
