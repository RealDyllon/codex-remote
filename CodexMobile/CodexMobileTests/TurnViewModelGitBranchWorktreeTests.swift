// FILE: TurnViewModelGitBranchWorktreeTests.swift
// Purpose: Verifies worktree-backed branches are exposed to the UI only when Git reports them as checked out elsewhere.
// Layer: Unit Test
// Exports: TurnViewModelGitBranchWorktreeTests
// Depends on: XCTest, CodexMobile

import XCTest
@testable import CodexMobile

@MainActor
final class TurnViewModelGitBranchWorktreeTests: XCTestCase {
    func testWorktreePathResolvesOnlyForBranchesCheckedOutElsewhere() {
        let viewModel = TurnViewModel()
        viewModel.gitBranchesCheckedOutElsewhere = ["codex-remote/feature-a"]
        viewModel.gitWorktreePathsByBranch = [
            "codex-remote/feature-a": "/tmp/codex-remote-feature-a",
            "main": "/tmp/codex-remote-main"
        ]

        XCTAssertEqual(
            viewModel.worktreePathForCheckedOutElsewhereBranch("codex-remote/feature-a"),
            "/tmp/codex-remote-feature-a"
        )
        XCTAssertNil(viewModel.worktreePathForCheckedOutElsewhereBranch("main"))
        XCTAssertNil(viewModel.worktreePathForCheckedOutElsewhereBranch("codex-remote/missing"))
    }

    func testApplyGitBranchTargetsStoresTrueLocalCheckoutPath() {
        let viewModel = TurnViewModel()
        let result = GitBranchesWithStatusResult(
            from: [
                "branches": .array([.string("main")]),
                "branchesCheckedOutElsewhere": .array([]),
                "worktreePathByBranch": .object([:]),
                "localCheckoutPath": .string("/tmp/codex-remote-local/codex-remote-bridge"),
                "current": .string("main"),
                "default": .string("main"),
            ]
        )

        viewModel.applyGitBranchTargets(result)

        XCTAssertEqual(viewModel.gitLocalCheckoutPath, "/tmp/codex-remote-local/codex-remote-bridge")
    }

    func testApplyGitBranchTargetsKeepsSelectedBaseBranchEmptyWhenDefaultIsRemoteOnly() {
        let viewModel = TurnViewModel()
        let result = GitBranchesWithStatusResult(
            from: [
                "branches": .array([.string("codex-remote/topic")]),
                "branchesCheckedOutElsewhere": .array([]),
                "worktreePathByBranch": .object([:]),
                "localCheckoutPath": .string("/tmp/codex-remote-local/codex-remote-bridge"),
                "current": .string("codex-remote/topic"),
                "default": .string("main"),
            ]
        )

        viewModel.applyGitBranchTargets(result)

        XCTAssertEqual(viewModel.gitDefaultBranch, "main")
        XCTAssertEqual(viewModel.selectedGitBaseBranch, "")
    }

    func testApplyGitBranchTargetsPreservesValidLocalBaseBranchSelection() {
        let viewModel = TurnViewModel()
        viewModel.selectedGitBaseBranch = "release/1.0"
        let result = GitBranchesWithStatusResult(
            from: [
                "branches": .array([.string("main"), .string("release/1.0"), .string("codex-remote/topic")]),
                "branchesCheckedOutElsewhere": .array([]),
                "worktreePathByBranch": .object([:]),
                "localCheckoutPath": .string("/tmp/codex-remote-local/codex-remote-bridge"),
                "current": .string("codex-remote/topic"),
                "default": .string("main"),
            ]
        )

        viewModel.applyGitBranchTargets(result)

        XCTAssertEqual(viewModel.selectedGitBaseBranch, "release/1.0")
    }
}
