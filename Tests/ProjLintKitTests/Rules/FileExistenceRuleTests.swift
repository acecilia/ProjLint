@testable import ProjLintKit
import XCTest

final class FileExistenceRuleTests: XCTestCase {
    let infoPlistResource = Resource(path: "Sources/SuportingFiles/Info.plist", contents: "<plist></plist>")

    func testExistingPaths() {
        resourcesLoaded([infoPlistResource]) {
            let optionsDict = ["existing_paths": [infoPlistResource.path]]
            let rule = FileExistenceRule(optionsDict)

            let violations = rule.violations(in: Resource.baseUrl)
            XCTAssert(violations.isEmpty)
        }

        resourcesLoaded([]) {
            let optionsDict = ["existing_paths": [infoPlistResource.path]]
            let rule = FileExistenceRule(optionsDict)

            let violations = rule.violations(in: Resource.baseUrl)
            XCTAssertEqual(violations.count, 1)
        }
    }

    func testNonExistingPaths() {
        resourcesLoaded([infoPlistResource]) {
            let optionsDict = ["non_existing_paths": [infoPlistResource.path]]
            let rule = FileExistenceRule(optionsDict)

            let violations = rule.violations(in: Resource.baseUrl)
            XCTAssertEqual(violations.count, 1)
        }

        resourcesLoaded([]) {
            let optionsDict = ["non_existing_paths": [infoPlistResource.path]]
            let rule = FileExistenceRule(optionsDict)

            let violations = rule.violations(in: Resource.baseUrl)
            XCTAssert(violations.isEmpty)
        }
    }

    func testExclusivelyExistingPaths() {
        resourcesLoaded([infoPlistResource]) {
            let optionsDict = ["exclusively_existing_paths": [infoPlistResource.relativePath]]
            let rule = FileExistenceRule(optionsDict)

            let violations = rule.violations(in: Resource.baseUrl)
            XCTAssertEqual(violations.count, 0)
        }

        resourcesLoaded([infoPlistResource]) {
            let optionsDict = [
                "exclusively_existing_paths": [
                    [
                        "Sources": [
                            [
                                "SuportingFiles": [
                                    "Info.plist"
                                ]
                            ]
                        ]
                    ]
                ]
            ]
            let rule = FileExistenceRule(optionsDict)

            let violations = rule.violations(in: Resource.baseUrl)
            XCTAssertEqual(violations.count, 0)
        }

        resourcesLoaded([infoPlistResource]) {
            let optionsDict = [
                "exclusively_existing_paths": [
                    [
                        "Sources": [
                            [
                                "SuportingFiles": [
                                    "*"
                                ]
                            ]
                        ]
                    ]
                ]
            ]
            let rule = FileExistenceRule(optionsDict)

            let violations = rule.violations(in: Resource.baseUrl)
            XCTAssertEqual(violations.count, 0)
        }

        resourcesLoaded([infoPlistResource]) {
            let optionsDict = [
                "exclusively_existing_paths": [
                    "*/*/*.plist"
                ]
            ]
            let rule = FileExistenceRule(optionsDict)

            let violations = rule.violations(in: Resource.baseUrl)
            XCTAssertEqual(violations.count, 0)
        }

        resourcesLoaded([infoPlistResource]) {
            let optionsDict = [
                "exclusively_existing_paths": [
                    "*/*/*.png"
                ]
            ]
            let rule = FileExistenceRule(optionsDict)

            let violations = rule.violations(in: Resource.baseUrl)
            XCTAssertEqual(violations.count, 1)
            XCTAssertEqual(violations.compactMap { ($0 as? FileViolation)?.path }, [infoPlistResource.path])
            XCTAssertEqual(violations.compactMap { ($0 as? FileViolation)?.message }, ["File exists, but it mustn\'t."])
        }

        resourcesLoaded([]) {
            let optionsDict = ["exclusively_existing_paths": [infoPlistResource.path]]
            let rule = FileExistenceRule(optionsDict)

            let violations = rule.violations(in: Resource.baseUrl)
            XCTAssertEqual(violations.count, 1)
        }
    }
}
