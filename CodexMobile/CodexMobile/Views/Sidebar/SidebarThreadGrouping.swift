// FILE: SidebarThreadGrouping.swift
// Purpose: Produces sidebar thread groups by project path (`cwd`) and keeps archived chats separate.
// Layer: View Helper
// Exports: SidebarThreadGroupKind, SidebarThreadGroup, SidebarThreadGrouping

import Foundation

enum SidebarThreadGroupKind: Equatable {
    case pinned
    case project
    case archived
}

struct SidebarProjectChoice: Identifiable, Equatable {
    let id: String
    let label: String
    let iconSystemName: String
    let projectPath: String
    let sortDate: Date
}

struct SidebarThreadGroup: Identifiable {
    let id: String
    let label: String
    let kind: SidebarThreadGroupKind
    let sortDate: Date
    let projectPath: String?
    let threads: [CodexThread]

    var iconSystemName: String {
        switch kind {
        case .pinned:
            return "pin"
        case .project:
            return CodexThread.projectIconSystemName(for: projectPath)
        case .archived:
            return "archivebox"
        }
    }

    func contains(_ thread: CodexThread) -> Bool {
        threads.contains(where: { $0.id == thread.id })
    }
}

enum SidebarThreadGrouping {
    static func makeGroups(
        from threads: [CodexThread],
        pinnedThreadIDs: [String] = [],
        now _: Date = Date(),
        calendar _: Calendar = .current
    ) -> [SidebarThreadGroup] {
        var groups: [SidebarThreadGroup] = []
        var archivedThreads: [CodexThread] = []
        let pinnedThreads = collectPinnedThreads(from: threads, pinnedRootThreadIDs: pinnedThreadIDs)
        let pinnedThreadIDSet = Set(pinnedThreads.map(\.id))

        for thread in threads {
            if thread.syncState == .archivedLocal {
                archivedThreads.append(thread)
            }
        }

        if let firstPinned = pinnedThreads.first {
            groups.append(
                SidebarThreadGroup(
                    id: "pinned",
                    label: "Pinned",
                    kind: .pinned,
                    sortDate: firstPinned.updatedAt ?? firstPinned.createdAt ?? .distantPast,
                    projectPath: nil,
                    threads: pinnedThreads
                )
            )
        }

        groups.append(
            contentsOf: makeProjectGroups(
                from: threads,
                excludingPinnedThreadIDs: pinnedThreadIDSet,
                collapseManagedWorktreesIntoProjectSections: true
            )
        )

        let sortedArchived = sortThreadsByRecentActivity(archivedThreads)
        if let firstArchived = sortedArchived.first {
            groups.append(
                SidebarThreadGroup(
                    id: "archived",
                    label: "Archived (\(sortedArchived.count))",
                    kind: .archived,
                    sortDate: firstArchived.updatedAt ?? firstArchived.createdAt ?? .distantPast,
                    projectPath: nil,
                    threads: sortedArchived
                )
            )
        }

        return groups
    }

    // Keeps project choices path-specific so the New Chat chooser can still target an existing worktree.
    static func makeProjectChoices(from threads: [CodexThread]) -> [SidebarProjectChoice] {
        makeProjectGroups(from: threads, collapseManagedWorktreesIntoProjectSections: false).compactMap { group in
            guard let projectPath = group.projectPath else {
                return nil
            }

            return SidebarProjectChoice(
                id: group.id,
                label: group.label,
                iconSystemName: group.iconSystemName,
                projectPath: projectPath,
                sortDate: group.sortDate
            )
        }
    }

    // Resolves all live thread ids that belong to the tapped project, even if the visible group is filtered.
    static func liveThreadIDsForProjectGroup(_ group: SidebarThreadGroup, in threads: [CodexThread]) -> [String] {
        guard group.kind == .project else {
            return []
        }

        return sortThreadsByRecentActivity(
            threads.filter { thread in
                thread.syncState != .archivedLocal && projectGroupID(for: thread, in: threads) == group.id
            }
        ).map(\.id)
    }

    private static func makeProjectGroup(
        projectKey: String,
        threads: [CodexThread],
        collapseManagedWorktreesIntoProjectSections: Bool
    ) -> SidebarThreadGroup {
        let sortedThreads = sortThreadsByRecentActivity(threads)
        let representativeThread = sortedThreads.first
        let projectPath = representativeProjectPath(
            from: sortedThreads,
            collapseManagedWorktreesIntoProjectSections: collapseManagedWorktreesIntoProjectSections
        )
        let sortDate = representativeThread?.updatedAt ?? representativeThread?.createdAt ?? .distantPast
        return SidebarThreadGroup(
            id: "project:\(projectKey)",
            label: projectDisplayLabel(
                for: projectPath,
                includeWorktreeToken: !collapseManagedWorktreesIntoProjectSections
            ),
            kind: .project,
            sortDate: sortDate,
            projectPath: projectPath,
            threads: sortedThreads
        )
    }

    // Keeps project-derived UI consistent by centralizing the live-thread → project bucket mapping.
    private static func makeProjectGroups(
        from threads: [CodexThread],
        excludingPinnedThreadIDs pinnedThreadIDs: Set<String> = [],
        collapseManagedWorktreesIntoProjectSections: Bool = true
    ) -> [SidebarThreadGroup] {
        var liveThreadsByProject: [String: [CodexThread]] = [:]
        let liveThreads = threads.filter { $0.syncState != .archivedLocal }
        let candidateThreads = threads.filter { thread in
            thread.syncState != .archivedLocal && !pinnedThreadIDs.contains(thread.id)
        }
        let mainProjectKeyByBaseName = uniqueMainProjectKeyByBaseName(from: liveThreads)

        for thread in candidateThreads {
            let projectKey = projectGroupKey(
                for: thread,
                mainProjectKeyByBaseName: mainProjectKeyByBaseName,
                collapseManagedWorktreesIntoProjectSections: collapseManagedWorktreesIntoProjectSections
            )
            liveThreadsByProject[projectKey, default: []].append(thread)
        }

        return liveThreadsByProject.map { projectKey, projectThreads in
            makeProjectGroup(
                projectKey: projectKey,
                threads: projectThreads,
                collapseManagedWorktreesIntoProjectSections: collapseManagedWorktreesIntoProjectSections
            )
        }
        .sorted { lhs, rhs in
            if lhs.sortDate != rhs.sortDate {
                return lhs.sortDate > rhs.sortDate
            }

            if lhs.label != rhs.label {
                return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
            }

            return lhs.id < rhs.id
        }
    }

    // Keeps pinned roots and their descendants together so sidebar trees do not split across sections.
    private static func collectPinnedThreads(
        from threads: [CodexThread],
        pinnedRootThreadIDs: [String]
    ) -> [CodexThread] {
        let liveThreads = threads.filter { $0.syncState != .archivedLocal }
        let threadsByID = Dictionary(uniqueKeysWithValues: liveThreads.map { ($0.id, $0) })
        let childrenByParentID = liveThreads.reduce(into: [String: [CodexThread]]()) { partialResult, thread in
            guard let parentThreadID = thread.parentThreadId else {
                return
            }
            partialResult[parentThreadID, default: []].append(thread)
        }
        var pinnedThreads: [CodexThread] = []
        var visitedThreadIDs: Set<String> = []

        for rootThreadID in pinnedRootThreadIDs {
            guard let rootThread = threadsByID[rootThreadID] else {
                continue
            }

            appendPinnedSubtree(
                rootThread,
                childrenByParentID: childrenByParentID,
                into: &pinnedThreads,
                visitedThreadIDs: &visitedThreadIDs
            )
        }

        return pinnedThreads
    }

    private static func appendPinnedSubtree(
        _ thread: CodexThread,
        childrenByParentID: [String: [CodexThread]],
        into pinnedThreads: inout [CodexThread],
        visitedThreadIDs: inout Set<String>
    ) {
        guard visitedThreadIDs.insert(thread.id).inserted else {
            return
        }

        pinnedThreads.append(thread)

        for childThread in childrenByParentID[thread.id] ?? [] {
            appendPinnedSubtree(
                childThread,
                childrenByParentID: childrenByParentID,
                into: &pinnedThreads,
                visitedThreadIDs: &visitedThreadIDs
            )
        }
    }

    private static func sortThreadsByRecentActivity(_ threads: [CodexThread]) -> [CodexThread] {
        threads.sorted { lhs, rhs in
            let lhsDate = lhs.updatedAt ?? lhs.createdAt ?? .distantPast
            let rhsDate = rhs.updatedAt ?? rhs.createdAt ?? .distantPast
            if lhsDate != rhsDate {
                return lhsDate > rhsDate
            }
            return lhs.id < rhs.id
        }
    }

    private static func projectGroupID(for thread: CodexThread, in threads: [CodexThread]) -> String {
        let liveThreads = threads.filter { $0.syncState != .archivedLocal }
        let mainProjectKeyByBaseName = uniqueMainProjectKeyByBaseName(from: liveThreads)
        let projectKey = projectGroupKey(
            for: thread,
            mainProjectKeyByBaseName: mainProjectKeyByBaseName,
            collapseManagedWorktreesIntoProjectSections: true
        )
        return "project:\(projectKey)"
    }

    private static func projectGroupKey(
        for thread: CodexThread,
        mainProjectKeyByBaseName: [String: String],
        collapseManagedWorktreesIntoProjectSections: Bool
    ) -> String {
        guard collapseManagedWorktreesIntoProjectSections,
              thread.isManagedWorktreeProject,
              let normalizedProjectPath = thread.normalizedProjectPath else {
            return thread.projectKey
        }

        let baseName = projectBaseDisplayName(for: normalizedProjectPath)
        return mainProjectKeyByBaseName[baseName] ?? "managed-worktree:\(baseName)"
    }

    private static func uniqueMainProjectKeyByBaseName(from threads: [CodexThread]) -> [String: String] {
        var projectKeysByBaseName: [String: Set<String>] = [:]

        for thread in threads where !thread.isManagedWorktreeProject {
            guard let normalizedProjectPath = thread.normalizedProjectPath else {
                continue
            }
            projectKeysByBaseName[projectBaseDisplayName(for: normalizedProjectPath), default: []].insert(thread.projectKey)
        }

        return projectKeysByBaseName.reduce(into: [String: String]()) { result, entry in
            guard entry.value.count == 1, let projectKey = entry.value.first else {
                return
            }
            result[entry.key] = projectKey
        }
    }

    private static func representativeProjectPath(
        from sortedThreads: [CodexThread],
        collapseManagedWorktreesIntoProjectSections: Bool
    ) -> String? {
        if collapseManagedWorktreesIntoProjectSections,
           let mainProjectPath = sortedThreads.first(where: { !$0.isManagedWorktreeProject })?.normalizedProjectPath {
            return mainProjectPath
        }

        return sortedThreads.first?.normalizedProjectPath
    }

    private static func projectDisplayLabel(for normalizedProjectPath: String?, includeWorktreeToken: Bool) -> String {
        guard let normalizedProjectPath else {
            return "No Project"
        }

        if includeWorktreeToken {
            return CodexThread.projectDisplayLabel(for: normalizedProjectPath)
        }

        return projectBaseDisplayName(for: normalizedProjectPath)
    }

    private static func projectBaseDisplayName(for normalizedProjectPath: String) -> String {
        let lastComponent = (normalizedProjectPath as NSString).lastPathComponent
        if !lastComponent.isEmpty, lastComponent != "/" {
            return lastComponent
        }

        return normalizedProjectPath
    }
}
