//
//  Access+Dump.swift
//  
//
//  Created by Kai Quan Tay on 10/7/24.
//

import AppKit
import OSLog

import Element
import Output

public extension Access {
    /// Dumps the system wide element to a property list file chosen by the user.
    @MainActor
    func dumpSystemWide() async {
        await dumpElement(system)
    }

    /// Dumps all accessibility elements of the currently active application to a property list file chosen by the user.
    @MainActor
    func dumpApplication() async {
        guard let application = await application else {
            let content = [OutputSemantic.noFocus]
            Output.shared.convey(content)
            return
        }
        await dumpElement(application)
    }

    /// Dumps all descendant accessibility elements of the currently focused element to a property list file chosen by
    /// the user.
    @MainActor
    func dumpFocus() async {
        guard let focus = await focus else {
            let content = [OutputSemantic.noFocus]
            Output.shared.convey(content)
            return
        }
        await dumpElement(focus.entity.element)
    }

    /// Dumps the entire hierarchy of elements rooted at the specified element to a property list file chosen
    /// by the user.
    /// - Parameter element: Root element.
    @MainActor
    internal func dumpElement(_ element: Element) async {
        do {
            guard let label = try await application?.getAttribute(.title) as? String,
                  let dump = try await element.dump() else {
                let content = [OutputSemantic.noFocus]
                Output.shared.convey(content)
                return
            }
            let data = try PropertyListSerialization.data(fromPropertyList: dump, format: .binary, options: .zero)
            print("Data: \(dump)")
            let savePanel = NSSavePanel()
            savePanel.canCreateDirectories = true
            savePanel.message = "Choose a location to dump the selected accessibility elements."
            savePanel.nameFieldLabel = "Accessibility Dump Property List"
            savePanel.nameFieldStringValue = "\(label) Dump.plist"
            savePanel.title = "Save \(label) dump property list"
            let response = await savePanel.begin()
            if response == .OK, let url = savePanel.url {
                try data.write(to: url)
            }
        } catch {
            await handleError(error)
        }
    }
}
