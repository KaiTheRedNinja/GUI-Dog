//
//  AccessDelegate.swift
//  
//
//  Created by Kai Quan Tay on 8/7/24.
//

import Foundation

public protocol AccessDelegate {
    /// Called when the ``Access`` instance refocuses after a change in application focus. Blocks the exiting of the refocus function.
    func accessDidRefocus(success: Bool)
}
