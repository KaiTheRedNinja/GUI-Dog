//
//  GoalViewController.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 21/7/24.
//

import AppKit
import SwiftUI

class GoalViewController: NSViewController {
    var goalsView: NSHostingView<GoalsView>
    var visible: Bool

    init() {
        let size = NSSize(width: 600, height: 55)

        self.goalsView = .init(rootView: .init(size: size, callback: nil))
        self.goalsView.frame = .init(origin: .zero, size: size)
        self.visible = false
        super.init(nibName: nil, bundle: nil)

        self.view = NSView(frame: .init(origin: .zero, size: size))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() { changeVisibility(visible: true) }
    func hide() { changeVisibility(visible: false) }

    func changeVisibility(visible: Bool) {
        self.visible = visible

        goalsView.removeFromSuperview()

        let frame = self.view.frame
        let view = NSView()
        view.frame = frame
        view.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(goalsView)

        let framesViewAnimator = goalsView.animator()
        framesViewAnimator.isHidden = !visible

        self.view = view
    }

    func setCallback(to callback: @escaping (String) -> Void) {
        goalsView.rootView.callback = callback
    }
}
