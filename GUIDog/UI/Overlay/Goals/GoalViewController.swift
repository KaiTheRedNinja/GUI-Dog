//
//  GoalViewController.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 21/7/24.
//

import AppKit
import SwiftUI

class GoalViewController: NSViewController {
    var goalsView: NSHostingView<GoalsView>

    init() {
        let size = NSSize(width: 600, height: 55)

        self.goalsView = .init(rootView: .init(size: size, callback: nil))
        self.goalsView.frame = .init(origin: .zero, size: size)
        super.init(nibName: nil, bundle: nil)

        self.view = NSView(frame: .init(origin: .zero, size: size))
        view.frame = .init(origin: .zero, size: size)
        view.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(goalsView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCallback(to callback: @escaping (String) -> Void) {
        goalsView.rootView.callback = callback
    }
}
