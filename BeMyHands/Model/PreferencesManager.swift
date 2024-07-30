//
//  PreferencesManager.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 28/7/24.
//

import Foundation
import Input
import Output
import OSLog

private let logger = Logger(subsystem: #fileID, category: "BeMyHands")

final class PreferencesManager {
    var userVisionStatus: UserVisionStatus = .sighted {
        didSet {
            Task { @MainActor in
                Output.shared.isEnabled = userVisionStatus.useAudioCues
            }
        }
    }

    var keyboardShortcut: KeyBinding = .init(
        browseMode: true,
        controlModifier: true,
        optionModifier: true,
        commandModifier: true,
        key: .keyboardL
    )

    private init() {}

    static var global: PreferencesManager = {
        // grab the preferences manager from storage, or create it if its not there yet
        if let existing = FileSystem.read(PreferencesManager.self, from: "preferences") {
            logger.info("Existing preferences found!")
            return existing
        }

        let new = PreferencesManager()
        logger.info("Created new pref manager!")
        FileSystem.write(new, to: "preferences")
        return new
    }()

    func save() {
        FileSystem.write(self, to: "preferences")
        logger.info("Written to \(FileSystem.path(file: "preferences"))")
    }
}

extension PreferencesManager: Codable {
    enum Keys: CodingKey {
        case userVisionStatus
        case keyboardShortcut
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(userVisionStatus, forKey: .userVisionStatus)
        try container.encode(keyboardShortcut, forKey: .keyboardShortcut)
    }

    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        self.init()
        self.userVisionStatus = try container.decode(UserVisionStatus.self, forKey: .userVisionStatus)
        self.keyboardShortcut = try container.decode(KeyBinding.self, forKey: .keyboardShortcut)
    }
}

enum UserVisionStatus: Codable, CaseIterable {
    case sighted
    case mildlyImpaired
    case impaired
    case blind

    var description: String {
        switch self {
        case .sighted: "Sighted"
        case .mildlyImpaired: "Mildly Impaired"
        case .impaired: "Impaired"
        case .blind: "Blind"
        }
    }

    var useAudioCues: Bool {
        switch self {
        case .sighted, .mildlyImpaired: false
        case .impaired, .blind: true
        }
    }
}
