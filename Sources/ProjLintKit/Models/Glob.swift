// This file is taken from the SwiftLint project
// https://github.com/realm/SwiftLint

import Foundation

#if canImport(Darwin)
import Darwin

private let globFunction = Darwin.glob
#elseif canImport(Glibc)
import Glibc

private let globFunction = Glibc.glob
#else
#error("Unsupported platform")
#endif

struct Glob {
    static func isGlob(_ pattern: String) -> Bool {
        let globCharset = CharacterSet(charactersIn: "*?[]")
        return pattern.rangeOfCharacter(from: globCharset) != nil
    }

    static func resolveGlob(_ pattern: String, at directory: String) -> [String] {
        let previousCurrentDirectoryPath = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(directory)

        var globResult = glob_t()
        defer {
            globfree(&globResult)
            FileManager.default.changeCurrentDirectoryPath(previousCurrentDirectoryPath)
        }

        let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
        guard globFunction(pattern.cString(using: .utf8)!, flags, nil, &globResult) == 0 else {
            return []
        }

        #if os(Linux)
        let matchCount = globResult.gl_pathc
        #else
        let matchCount = globResult.gl_matchc
        #endif

        return (0..<Int(matchCount)).compactMap { index in
            return globResult.gl_pathv[index].flatMap { String(validatingUTF8: $0) }
        }
    }
}
