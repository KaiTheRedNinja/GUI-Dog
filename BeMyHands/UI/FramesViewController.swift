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

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView(with frame: NSRect, actionableElements: [ActionableElement]) {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = true
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
            elemView.layer?.borderWidth = 2
            elemView.layer?.borderColor = .init(red: 1, green: 0, blue: 0, alpha: 0.5)
            elemView.toolTip = element.actions.joined(separator: ", ")
            elemView.frame = convertedFrame

            view.addSubview(elemView)
        }

        self.view = view
    }
}
