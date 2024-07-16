//
//  ContentViewController.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import AppKit
import SwiftUI
import Element

class ContentViewController: NSViewController {
    var framesView: FramesView
    var stepsView: NSHostingView<StepsView>

    init() {
        self.framesView = .init(frame: .zero)
        self.stepsView = .init(rootView: .init(size: .zero))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupFrames(with frame: NSRect, actionableElements: [ActionableElement]) {
        framesView.removeFromSuperview()
        stepsView.removeFromSuperview()
        framesView.setupView(with: frame, actionableElements: actionableElements)

        let view = NSView()
        view.frame = frame
        view.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(framesView)
        view.addSubview(stepsView)

        self.view = view
    }

    func setupSteps(with context: ActionStepContext?) {
        print("SET UP STEPS")

        let frame = self.view.frame

        let stepsFrame: NSRect = .init(
            x: frame.width*3/4,
            y: 0,
            width: frame.width/4,
            height: frame.height
        )

        framesView.removeFromSuperview()
        stepsView.removeFromSuperview()
        stepsView = .init(rootView: .init(stepContext: context, size: stepsFrame.size))
        stepsView.frame = stepsFrame

        let view = NSView()
        view.frame = self.view.frame
        view.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(framesView)
        view.addSubview(stepsView)

        self.view = view
    }
}
