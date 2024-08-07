//
//  FramesViewController.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 8/7/24.
//

import AppKit
import SwiftUI
import Access
import HandsBot

class FramesViewController: NSViewController {
    var framesView: FramesView
    var visible: Bool

    init() {
        self.framesView = .init(frame: .zero)
        self.visible = false
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupFrames(with frame: NSRect, actionableElements: [ActionableElement]) {
        framesView.removeFromSuperview()
        framesView.setupView(with: frame, actionableElements: actionableElements)

        let view = NSView()
        view.frame = frame
        view.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(framesView)

        self.view = view
    }

    func show() { changeVisibility(visible: true) }
    func hide() { changeVisibility(visible: false) }

    func changeVisibility(visible: Bool) {
        self.visible = visible

        framesView.removeFromSuperview()

        let frame = self.view.frame
        let view = NSView()
        view.frame = frame
        view.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(framesView)

        let framesViewAnimator = framesView.animator()
        framesViewAnimator.isHidden = !visible

        self.view = view
    }
}
