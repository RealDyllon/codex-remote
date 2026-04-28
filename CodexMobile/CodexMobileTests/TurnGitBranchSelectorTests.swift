// FILE: TurnGitBranchSelectorTests.swift
// Purpose: Verifies new branch creation names normalize toward the codex-remote/ prefix without double-prefixing.
// Layer: Unit Test
// Exports: TurnGitBranchSelectorTests
// Depends on: XCTest, CodexMobile

import XCTest
@testable import CodexMobile

final class TurnGitBranchSelectorTests: XCTestCase {
    func testNormalizesCreatedBranchNamesTowardCodexRemotePrefix() {
        XCTAssertEqual(codexRemoteNormalizedCreatedBranchName("foo"), "codex-remote/foo")
        XCTAssertEqual(codexRemoteNormalizedCreatedBranchName("codex-remote/foo"), "codex-remote/foo")
        XCTAssertEqual(codexRemoteNormalizedCreatedBranchName("  foo  "), "codex-remote/foo")
    }

    func testNormalizesEmptyBranchNamesToEmptyString() {
        XCTAssertEqual(codexRemoteNormalizedCreatedBranchName("   "), "")
    }

    func testCurrentBranchSelectionDisablesCheckedOutElsewhereRowsWhenWorktreePathIsMissing() {
        XCTAssertTrue(
            codexRemoteCurrentBranchSelectionIsDisabled(
                branch: "codex-remote/feature-a",
                currentBranch: "main",
                gitBranchesCheckedOutElsewhere: ["codex-remote/feature-a"],
                gitWorktreePathsByBranch: [:],
                allowsSelectingCurrentBranch: true
            )
        )
    }

    func testCurrentBranchSelectionKeepsCheckedOutElsewhereRowsEnabledWhenWorktreePathExists() {
        XCTAssertFalse(
            codexRemoteCurrentBranchSelectionIsDisabled(
                branch: "codex-remote/feature-a",
                currentBranch: "main",
                gitBranchesCheckedOutElsewhere: ["codex-remote/feature-a"],
                gitWorktreePathsByBranch: ["codex-remote/feature-a": "/tmp/codex-remote-feature-a"],
                allowsSelectingCurrentBranch: true
            )
        )
    }

    func testSelectableDefaultBranchReturnsNilWhenDefaultIsNotLocal() {
        XCTAssertNil(
            codexRemoteSelectableDefaultBranch(
                defaultBranch: "main",
                availableGitBranchTargets: ["codex-remote/feature-a"]
            )
        )
    }

    func testSelectableDefaultBranchReturnsDefaultWhenItIsLocal() {
        XCTAssertEqual(
            codexRemoteSelectableDefaultBranch(
                defaultBranch: "main",
                availableGitBranchTargets: ["main", "codex-remote/feature-a"]
            ),
            "main"
        )
    }
}
