import Foundation

struct FileExistenceRule: Rule {
    static let name: String = "File Existence"
    static let identifier: String = "file_existence"

    private let defaultViolationLevel: ViolationLevel = .warning
    private let options: FileExistenceOptions

    init(_ optionsDict: [String: Any]) {
        options = FileExistenceOptions(optionsDict, rule: type(of: self))
    }

    func violations(in directory: URL) -> [Violation] {
        var violations = [Violation]()

        if let existingPaths = options.existingPaths {
            for path in existingPaths {
                if !FileManager.default.fileExists(atPath: path) {
                    violations.append(
                        FileViolation(
                            rule: self,
                            message: "Expected file to exist but didn't.",
                            level: options.violationLevel(defaultTo: defaultViolationLevel),
                            path: path
                        )
                    )
                }
            }
        }

        if let nonExistingPaths = options.nonExistingPaths {
            for path in nonExistingPaths {
                if FileManager.default.fileExists(atPath: path) {
                    violations.append(
                        FileViolation(
                            rule: self,
                            message: "Expected file not to exist but existed.",
                            level: options.violationLevel(defaultTo: defaultViolationLevel),
                            path: path
                        )
                    )
                }
            }
        }

        if let exclusivelyExistingPaths = options.exclusivelyExistingPaths {
            let expectedFileStructure = Set(files(for: exclusivelyExistingPaths, parentPathComponents: [], currentDirectory: directory.path))
            let existingFileStructure = Set(getFiles(at: directory.path))

            let nonExistantFilesThatMustExist = expectedFileStructure.filter { existingFileStructure.contains($0) == false }
            let existantFilesThatMustNotExist = existingFileStructure.filter { expectedFileStructure.contains($0) == false }

            nonExistantFilesThatMustExist.forEach {
                let violation = FileViolation(
                    rule: self,
                    message: "File was expected to exist, but it doesn't.",
                    level: options.violationLevel(defaultTo: defaultViolationLevel),
                    path: $0
                )
                violations.append(violation)
            }

            existantFilesThatMustNotExist.forEach {
                let violation = FileViolation(
                    rule: self,
                    message: "File exists, but it mustn't.",
                    level: options.violationLevel(defaultTo: defaultViolationLevel),
                    path: $0
                )
                violations.append(violation)
            }
        }

        return violations
    }

    private func getFiles(at path: String) -> [String] {
        var files: [String] = []

        let resourceKeys: [URLResourceKey] = [.creationDateKey, .isRegularFileKey]
        let currentUrl = URL(fileURLWithPath: path)
        let enumerator = FileManager.default.enumerator(
            at: currentUrl,
            includingPropertiesForKeys: resourceKeys
            )!

        for case let fileUrl as URL in enumerator {
            let resourceValues = try! fileUrl.resourceValues(forKeys: Set(resourceKeys))
            if resourceValues.isRegularFile! {
                files.append(fileUrl.path)
            }
        }

        return files
    }

    private func files(for substructure: [XcodeProjectNavigatorOptions.TreeNode], parentPathComponents: [String], currentDirectory: String) -> [String] {
        var files = [String]()

        for node in substructure {
            switch node {
            case let .leaf(fileName):
                let path = (parentPathComponents + [fileName]).joined(separator: "/")
                if Glob.isGlob(path) {
                    let matchedFiles = Glob.resolveGlob(path, at: currentDirectory).map { "\(currentDirectory)/\($0)" }
                    files.append(contentsOf: matchedFiles)
                } else {
                    files.append("\(currentDirectory)/\(path)")
                }

            case let .subtree(groupName, subnodes):
                files += self.files(for: subnodes, parentPathComponents: parentPathComponents + [groupName], currentDirectory: currentDirectory)
            }
        }

        return files
    }
}
