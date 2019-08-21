import Foundation

class FileExistenceOptions: RuleOptions {
    let existingPaths: [String]?
    let nonExistingPaths: [String]?
    let exclusivelyExistingPaths: [XcodeProjectNavigatorOptions.TreeNode]?

    override init(_ optionsDict: [String: Any], rule: Rule.Type) {
        self.existingPaths = RuleOptions.optionalStringArray(forOption: "existing_paths", in: optionsDict, rule: rule)
        self.nonExistingPaths = RuleOptions.optionalStringArray(forOption: "non_existing_paths", in: optionsDict, rule: rule)
        self.exclusivelyExistingPaths = FileExistenceOptions.orderedStructure(forOption: "exclusively_existing_paths", in: optionsDict, rule: rule)
        super.init(optionsDict, rule: rule)
    }

    private static func orderedStructure(forOption optionName: String, in optionsDict: [String: Any], rule: Rule.Type) -> [XcodeProjectNavigatorOptions.TreeNode]? {
        guard RuleOptions.optionExists(optionName, in: optionsDict, required: false, rule: rule) else {
            return nil
        }

        guard let anyArray = optionsDict[optionName] as? [Any] else {
            let message = """
            Could not read option `\(optionName)` for rule \(rule.identifier) from config file.
            Expected value to be of type `[Any]`. Value: \(String(describing: optionsDict[optionName]))
            """
            print(message, level: .error)
            exit(EX_USAGE)
        }

        return XcodeProjectNavigatorOptions.treeNodes(from: anyArray)
    }
}
