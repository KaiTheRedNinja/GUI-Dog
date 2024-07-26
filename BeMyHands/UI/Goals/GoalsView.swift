//
//  GoalsView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 21/7/24.
//

import Cocoa

class GoalsView: NSView {
//    var textField: GoalsTextField

    override init(frame frameRect: NSRect) {
//        self.textField = .init(frame: frameRect)
        super.init(frame: frameRect)

//        textField.bezelStyle = .roundedBezel
//        self.addSubview(textField)
    }

    required init?(coder: NSCoder) {
        fatalError("Not Implemented")
    }

    func setCallback(to callback: @escaping (String) -> Void) {
//        textField.callback = callback
    }
}

class GoalsTextField: NSTextField {
    var callback: ((String) -> Void)!

    override func textDidEndEditing(_ notification: Notification) {
//        callback(self.stringValue)
//        callback = nil
    }
}
