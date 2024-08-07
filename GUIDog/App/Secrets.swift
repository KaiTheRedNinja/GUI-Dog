//
//  Secrets.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 15/7/24.
//

// NOTE: DO NOT EVER COMMIT THIS TO GIT. EVER.

/// Object to hold secrets, such as the Gemini API key
///
/// Use this code to encode your api keys:
/// ```swift
/// import Foundation
/// let clear: [UInt8] = [UInt8]("My_API_Key_Here".data(using: .utf8)!)
/// let random: [UInt8] = (0..<clear.count).map { _ in UInt8(arc4random_uniform(256)) }
/// let obfuscated: [UInt8] = zip(clear, random).map(^)
///
/// print(obfuscated + random)
/// ```
///
/// Credits: https://www.splinter.com.au/2019/05/05/obfuscating-keys/
enum Secrets {
    private static let obfuscatedKey: [UInt8] = [
        203, 169, 121, 173, 161, 86, 253, 246, 184, 153,
        91, 254, 105, 246, 35, 42, 193, 92, 78, 96, 147,
        47, 117, 19, 93, 76, 37, 217, 29, 196, 47, 14,
        23, 82, 50, 218, 69, 200, 112, 138, 224, 3, 204,
        242, 47, 188, 207, 140, 251, 62, 178, 61, 172,
        64, 103, 133, 5, 60, 6, 160, 94, 63, 121, 59,
        124, 108, 150, 75, 171, 96, 116, 77, 60, 107,
        128, 51, 251, 31
    ]

    /// API key for the Gemini Large Language Model
    static var geminiKey: String {
        return String(
            bytes: deobfuscate(obfuscatedKey),
            encoding: .utf8
        )!
    }
}

private func deobfuscate(_ array: [UInt8]) -> [UInt8] {
    let start = array.prefix(array.count / 2)
    let end = array.suffix(array.count / 2)
    return zip(start, end).map(^)
}
