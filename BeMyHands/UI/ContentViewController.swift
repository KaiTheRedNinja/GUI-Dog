//
//  ContentViewController.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import AppKit
import SwiftUI
import Element
import HandsBot

class ContentViewController: NSViewController {
    var framesView: FramesView
    var stateView: NSHostingView<LLMStateView>
    var visible: Bool

    init() {
        self.framesView = .init(frame: .zero)
        self.stateView = .init(
            rootView: .init(
                state: LLMState.zero,
                size: NSSize.zero,
                isShown: false
            )
        )
        self.visible = false
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupFrames(with frame: NSRect, actionableElements: [ActionableElement]) {
        framesView.removeFromSuperview()
        stateView.removeFromSuperview()
        framesView.setupView(with: frame, actionableElements: actionableElements)

        let view = NSView()
        view.frame = frame
        view.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(framesView)
        view.addSubview(stateView)

        self.view = view
    }

    func setupState(with state: LLMState) {
        let frame = self.view.frame

        let stepsFrame: NSRect = .init(
            x: frame.width*3/4,
            y: 0,
            width: frame.width/4,
            height: frame.height
        )

        framesView.removeFromSuperview()
        stateView.removeFromSuperview()
        stateView = .init(
            rootView: .init(
                state: state,
                size: stepsFrame.size,
                isShown: visible
            )
        )
        stateView.frame = stepsFrame

        let view = NSView()
        view.frame = self.view.frame
        view.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(framesView)
        view.addSubview(stateView)

        self.view = view
    }

    func show() { changeVisibility(visible: true) }
    func hide() { changeVisibility(visible: false) }

    func changeVisibility(visible: Bool) {
        self.visible = visible

        stateView.removeFromSuperview()
        framesView.removeFromSuperview()

        let framesViewAnimator = framesView.animator()
        framesViewAnimator.isHidden = !visible

        let frame = self.view.frame
        let stepsFrame: NSRect = .init(
            x: frame.width*3/4,
            y: 0,
            width: frame.width/4,
            height: frame.height
        )

        stateView = .init(
            rootView: .init(
                state: stateView.rootView.state,
                size: stateView.rootView.size,
                isShown: visible
            )
        )
        stateView.frame = stepsFrame

        let view = NSView()
        view.frame = self.view.frame
        view.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(framesView)
        view.addSubview(stateView)

        self.view = view
    }
}
