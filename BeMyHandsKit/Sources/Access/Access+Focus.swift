//
//  Access+Focus.swift
//  
//
//  Created by Kai Quan Tay on 10/7/24.
//

import AppKit
import OSLog

import Element
import Output

public extension Access {
    /// Returns the currently focused window
    @MainActor
    func focusedWindow() async throws -> Element? {
        guard let application = await application else {
            let content = [OutputSemantic.noFocus]
            Output.shared.convey(content)
            return nil
        }
        let focusedWindow = try await application.getAttribute(.focusedWindow)
        if let focusedWindow {
            return focusedWindow as? Element
        }
        return nil
    }

    /// Reads the accessibility contents of the element with user focus.
    func readFocus() async {
        do {
            guard let focus = focus else {
                let content = [OutputSemantic.noFocus]
                await Output.shared.convey(content)
                return
            }
            let content = try await focus.reader.read()
            await Output.shared.convey(content)
        } catch {
            await handleError(error)
        }
    }

    /// Moves the user focus to its interesting parent.
    func focusParent() async {
        do {
            guard let oldFocus = focus else {
                let content = [OutputSemantic.noFocus]
                await Output.shared.convey(content)
                return
            }
            guard let parent = try await oldFocus.entity.getParent() else {
                var content = [OutputSemantic.boundary]
                content.append(contentsOf: try await oldFocus.reader.read())
                await Output.shared.convey(content)
                return
            }
            let newFocus = try await AccessFocus(on: parent)
            self.focus = newFocus
            try await newFocus.entity.setKeyboardFocus()
            var content = [OutputSemantic.exiting]
            content.append(contentsOf: try await newFocus.reader.readSummary())
            await Output.shared.convey(content)
        } catch {
            await handleError(error)
        }
    }

    /// Moves the user focus to its next interesting sibling.
    /// - Parameter backwards: Whether to search backwards.
    func focusNextSibling(backwards: Bool) async {
        do {
            guard let oldFocus = focus else {
                let content = [OutputSemantic.noFocus]
                await Output.shared.convey(content)
                return
            }
            guard let sibling = try await oldFocus.entity.getNextSibling(backwards: backwards) else {
                var content = [OutputSemantic.boundary]
                content.append(contentsOf: try await oldFocus.reader.read())
                await Output.shared.convey(content)
                return
            }
            let newFocus = try await AccessFocus(on: sibling)
            self.focus = newFocus
            try await newFocus.entity.setKeyboardFocus()
            var content = [!backwards ? OutputSemantic.next : OutputSemantic.previous]
            content.append(contentsOf: try await newFocus.reader.read())
            await Output.shared.convey(content)
        } catch {
            await handleError(error)
        }
    }

    /// Sets the user focus to the first child of this entity.
    func focusFirstChild() async {
        do {
            guard let oldFocus = focus else {
                let content = [OutputSemantic.noFocus]
                await Output.shared.convey(content)
                return
            }
            guard let child = try await oldFocus.entity.getFirstChild() else {
                var content = [OutputSemantic.boundary]
                content.append(contentsOf: try await oldFocus.reader.read())
                await Output.shared.convey(content)
                return
            }
            let newFocus = try await AccessFocus(on: child)
            self.focus = newFocus
            try await newFocus.entity.setKeyboardFocus()
            var content = [OutputSemantic.entering]
            content.append(contentsOf: try await oldFocus.reader.readSummary())
            content.append(contentsOf: try await newFocus.reader.read())
            await Output.shared.convey(content)
        } catch {
            await handleError(error)
        }
    }

    /// Resets the user focus to the system keyboard focusor the first interesting child of the
    /// focused window.
    internal func refocus(processIdentifier: pid_t?) async {
        do {
            guard let processIdentifier = processIdentifier else {
                application = nil
                self.processIdentifier = 0
                observer = nil
                focus = nil
                let content = [OutputSemantic.noFocus]
                await Output.shared.convey(content)
                return
            }
            var content = [OutputSemantic]()
            if processIdentifier != self.processIdentifier {
                let application = await Element(processIdentifier: processIdentifier)
                let observer = try await ElementObserver(element: application)
                try await observer.subscribe(to: .applicationDidAnnounce)
                try await observer.subscribe(to: .elementDidDisappear)
                try await observer.subscribe(to: .elementDidGetFocus)
                self.application = application
                self.processIdentifier = processIdentifier
                self.observer = observer
                let applicationLabel = try await application.getAttribute(.title) as? String
                content.append(.application(applicationLabel ?? "Application"))
            }
            guard let application = self.application, let observer = self.observer else {
                fatalError("Logic failed")
            }
            if let keyboardFocus = try await application.getAttribute(.focusedElement) as? Element {
                if let window = try await keyboardFocus.getAttribute(.windowElement) as? Element {
                    if let windowLabel = try await window.getAttribute(.title) as? String, !windowLabel.isEmpty {
                        content.append(.window(windowLabel))
                    } else {
                        content.append(.window("Untitled"))
                    }
                }
                let focus = try await AccessFocus(on: keyboardFocus)
                self.focus = focus
                content.append(contentsOf: try await focus.reader.read())
            } else if let window = try await application.getAttribute(.focusedWindow) as? Element,
                      let child = try await AccessEntity(for: window).getFirstChild() {
                if let windowLabel = try await window.getAttribute(.title) as? String, !windowLabel.isEmpty {
                    content.append(.window(windowLabel))
                } else {
                    content.append(.window("Untitled"))
                }
                let focus = try await AccessFocus(on: child)
                self.focus = focus
                content.append(contentsOf: try await focus.reader.read())
            } else {
                self.focus = nil
                try await observer.subscribe(to: .elementDidAppear)
                content.append(.noFocus)
            }
            //            print("Content: \(content)")
            //            await Output.shared.convey(content)

            delegate?.accessDidRefocus(success: true)
        } catch {
            print("Failed: \(error)")
            await handleError(error)

            delegate?.accessDidRefocus(success: false)
        }
    }

}
