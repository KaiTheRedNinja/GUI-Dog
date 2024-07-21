//
//  StatusViewController.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 21/7/24.
//

import AppKit
import SwiftUI
import Element
import HandsBot

class StatusViewController: NSViewController {
    var stateView: NSHostingView<LLMStateView>

    init() {
        self.stateView = .init(
            rootView: .init(
                state: LLMState.zero,
                size: NSSize.zero,
                isShown: true
            )
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupState(frame: NSRect, with state: LLMState) {
        let stepsFrame: NSRect = .init(
            x: frame.width*3/4,
            y: 0,
            width: frame.width/4,
            height: frame.height
        )

        stateView.removeFromSuperview()
        stateView = .init(
            rootView: .init(
                state: state,
                size: stepsFrame.size,
                isShown: true // TODO: make this work
            )
        )
        stateView.frame = stepsFrame

        let view = NSView()
        view.frame = self.view.frame
        view.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(stateView)

        self.view = view
    }
}
