//
//  HandsBot+Interface.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 19/7/24.
//

import Foundation

extension HandsBot {
    /// Sets `state` to `.step`, starting at step zero for steps. Should only be called ONCE, and will
    /// fatal error if called multiple times on the same instance.
    internal func addStep(_ step: String) {
        state.overallState = .working
        state.steps.append(.init(step: step))
    }

    /// Updates the state to being complete
    internal func updateStateToComplete() {
        state.overallState = .complete
    }

    /// Updates the state's current step to an error. Note that this will end communication.
    internal func updateState(toError error: LLMCommunicationError) {
        state.overallState = .error(error)
    }
}
