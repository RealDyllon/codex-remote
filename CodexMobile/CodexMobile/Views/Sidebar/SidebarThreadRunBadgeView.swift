// FILE: SidebarThreadRunBadgeView.swift
// Purpose: Renders the compact run-state indicator dot for sidebar conversation rows.
// Layer: View Component
// Exports: SidebarThreadRunBadgeView
// Depends on: SwiftUI, CodexThreadRunBadgeState

import SwiftUI

struct SidebarThreadRunBadgeView: View {
    let state: CodexThreadRunBadgeState

    var body: some View {
        Group {
            switch state {
            case .running:
                ProgressView()
                    .controlSize(.mini)
                    .tint(.secondary)
                    .frame(width: 14, height: 14)
            case .pendingApproval, .ready, .failed:
                Circle()
                    .fill(state.color)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 1)
                    )
                    .frame(width: 14, height: 14)
            }
        }
        .accessibilityHidden(true)
    }
}

private extension CodexThreadRunBadgeState {
    var color: Color {
        switch self {
        case .pendingApproval:
            return .green
        case .running:
            return .secondary
        case .ready:
            return .blue
        case .failed:
            return .red
        }
    }
}
