// FILE: SidebarThreadRunBadgeView.swift
// Purpose: Renders the compact run-state indicator for sidebar conversation rows.
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
                    .progressViewStyle(.circular)
                    .controlSize(.mini)
                    .tint(.blue)
                    .frame(width: 12, height: 12)
            case .ready, .failed:
                Circle()
                    .fill(state.dotColor)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 1)
                    )
            }
        }
        .accessibilityHidden(true)
    }
}

private extension CodexThreadRunBadgeState {
    var dotColor: Color {
        switch self {
        case .running:
            return .blue
        case .ready:
            return .green
        case .failed:
            return .red
        }
    }
}
