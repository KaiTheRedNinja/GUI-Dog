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
    internal func setup(withGoal goal: String, steps: [String]) {
        assert(state.steps.isEmpty, "Steps must not have existed during setup")
        state = .init(
            goal: goal,
            steps: steps.map { .init(step: $0, state: .notReached) }
        )
        /// Switches to the first step
        updateStateToNextStep()
    }

    /// Switches to the next step in the state.
    ///
    /// This is called by ``setup(withGoal:steps:)`` to switch to the first step.
    internal func updateStateToNextStep() {
        if (state.currentStepIndex ?? -1) >= 0 { // complete the current step
            self.state.currentStep.state = .complete
        }
        // increase step index
        self.state.currentStepIndex = (state.currentStepIndex ?? -1) + 1
        // prepare new step, if exists
        if state.currentStepIndex < state.steps.count {
            self.state.currentStep.state = .working(.init(pastActions: []))
        }
    }

    /// Updates the state's current step to a new context
    internal func updateState(toStep newStepContext: ActionStepContext) {
        self.state.currentStep.state = .working(newStepContext)
    }

    /// Updates the state's current step to an error. Note that this will end communication.
    internal func updateState(toError error: LLMCommunicationError) {
        if (state.currentStepIndex ?? -1) >= 0 {
            self.state.currentStep.state = .error(error)
        } else {
            self.state.steps = [.init(step: "Error obtaining steps", state: .error(error))]
        }
    }
}
