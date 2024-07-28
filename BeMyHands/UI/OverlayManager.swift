//
//  OverlayManager.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import AppKit
import Element
import HandsBot
import OSLog
import Output

private let logger = Logger(subsystem: #fileID, category: "BeMyHands")

@MainActor
class OverlayManager: LLMDisplayDelegate, AccessDisplayDelegate {
    private var framesWindowController: FramesWindowController
    private var framesController: FramesViewController

    private var statusWindowController: StatusWindowController
    private var statusController: StatusViewController

    private var goalWindowController: GoalsWindowController
    private var goalController: GoalViewController

    private var lastState: LLMState?

    init() {
        framesWindowController = .init()
        framesController = .init()
        statusWindowController = .init()
        statusController = .init()
        goalWindowController = .init()
        goalController = .init()
        framesWindowController.window?.contentViewController = framesController
        statusWindowController.window?.contentViewController = statusController
        goalWindowController.window?.contentViewController = goalController
    }

    func requestGoal() async -> String? {
        // Obtain the size of the screen
        guard let screenFrame = NSScreen.main?.frame else {
            fatalError("Could not get screen size")
        }
        let screenSize = screenFrame.size

        // Position the window to be in the center of the screen
        let goalWindowSize = NSSize(width: 600, height: 55)

        // The relative positioning, where 0.5 is halfway through the screen.
        // Note that the coordinate system starts from the bottom of the screen, so smaller
        // numbers are closer to the bottom
        let relativePosition = NSPoint(x: 0.5, y: 0.6)

        // Set the position of the window
        goalWindowController.window?.setFrameOrigin(
            .init(
                x: screenFrame.minX + screenSize.width*relativePosition.x - (goalWindowSize.width/2),
                y: screenFrame.minY + screenSize.height*relativePosition.y - (goalWindowSize.height/2)
            )
        )

        goalWindowController.showWindow(nil)
        goalWindowController.window?.makeKeyAndOrderFront(nil)
        goalWindowController.window?.orderFrontRegardless()

        let value = await withCheckedContinuation { cont in
            var triggered: Bool = false
            goalController.setCallback { value in
                guard !triggered else { return }
                triggered = true
                cont.resume(returning: value)
            }
        }

        goalWindowController.close()

        if value.isEmpty {
            return nil
        } else {
            return value
        }
    }

    func abortGoalRequest() async {
        // Goal window must be open
        guard goalWindowController.window?.isVisible ?? false else { return }
        // Trigger its request
        goalController.goalsView.rootView.callback?("")
    }

    func update(actionableElements: [ActionableElement]) async {
        // Obtain the size of the screen
        guard let screenSize = NSScreen.main?.frame.size else {
            fatalError("Could not get screen size")
        }

        // Set up the size and position of the frames controller
        self.framesController.setupFrames(
            with: .init(origin: .zero, size: screenSize),
            actionableElements: actionableElements
        )
        framesWindowController.window?.setFrameOrigin(.init(x: 0, y: 0))
    }

    func update(state: LLMState) {
        guard state != lastState else { return }
        lastState = state

        announceStateChange(state)

        // Obtain the size of the screen
        guard let screenSize = NSScreen.main?.frame.size else {
            fatalError("Could not get screen size")
        }

        self.statusController.setupFrames(
            with: .init(origin: .zero, size: screenSize)
        )
        self.statusController.setupState(with: state)
        statusWindowController.window?.setFrameOrigin(.init(x: 0, y: 0))
    }

    func show() {
        for windowController in [framesWindowController, statusWindowController] {
            windowController.showWindow(nil)
            windowController.window?.makeKeyAndOrderFront(nil)
            windowController.window?.orderFrontRegardless()
        }

        framesController.show()
        statusController.show()
    }

    func hide() {
        framesController.hide()
        statusController.hide()
    }

    private func announceStateChange(_ state: LLMState) {
        // if state is an error, announce it
        switch state.overallState {
        case .stepsNotLoaded:
            Output.shared.announce("Starting goal: \(state.goal)")
        case .complete:
            Output.shared.announce("Goal complete")
        case .error(let lLMCommunicationError):
            Output.shared.announce("BeMyHands encountered an error: \(lLMCommunicationError.description)")
        default:
            // figure out which step we're on
            // the step we're on will be the first step that is not "not reached"
            if let step = state.steps.first(where: {
                // the state is not .notReached or .complete
                ![LLMStepState.notReached, .complete].contains($0.state)
            }) {
                // step.step has a prefix of the number, so we don't need to duplicate it
                Output.shared.announce("Step \(step.step)")
            }
            // if none of the steps are "not reached", that means that we're supposed to be complete
            // but for some reason we aren't. Don't say anything.
        }
    }
}
