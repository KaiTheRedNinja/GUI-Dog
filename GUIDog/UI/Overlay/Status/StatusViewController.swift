//
//  StatusViewController.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 21/7/24.
//

import AppKit
import SwiftUI
import Element
import HandsBot

class StatusViewController: NSViewController {
    var stateView: NSHostingView<LLMStateView>!
    var stateObject: LLMStateObject!

    init() {
        self.stateObject = .init(state: .zero, isShown: false, size: .zero)
        self.stateView = .init(
            rootView: .init(stateObject: self.stateObject)
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupFrames(with frame: NSRect) {
        stateView.removeFromSuperview()

        let view = NSView()
        view.frame = frame
        view.translatesAutoresizingMaskIntoConstraints = true
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

        stateView.removeFromSuperview()
        stateObject.size = stepsFrame.size
        stateObject.state = state
        stateView.frame = stepsFrame

        let view = NSView()
        view.frame = self.view.frame
        view.wantsLayer = true
        view.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(stateView)

        self.view = view
    }

    func show() {
        stateObject.isShown = true

        setupState(with: .zero)
    }
    func hide() {
        DispatchQueue.main.asyncAfter(deadline: .now() + stateObject.hideDelay) { [weak self] in
            guard let self else { return }

            hideNow()
        }
    }

    func hideNow() {
        stateObject.isShown = false
        setupState(with: stateObject.state)
    }
}
