import SwiftUI

/// Resolves against the complete hidden set so searching does not rename projects.
/// Identical full paths share a label: this identifies projects, not sessions.
struct RecoveryProjectLabels {
    private let labels: [String: String]

    init(paths: [String?]) {
        let paths = Set(paths.compactMap(Self.path))
        let components = Dictionary(uniqueKeysWithValues: paths.map { ($0, $0.split(separator: "/").map(String.init)) })
        var resolved: [String: String] = [:]
        for path in paths {
            let parts = components[path] ?? []
            var label = path
            for depth in 1...max(1, parts.count) {
                let suffix = Array(parts.suffix(depth))
                let ambiguous = paths.contains { other in
                    other != path && Array((components[other] ?? []).suffix(depth)) == suffix
                }
                if !ambiguous && !suffix.isEmpty {
                    label = suffix.joined(separator: "/")
                    break
                }
            }
            resolved[path] = label
        }
        labels = resolved
    }

    func label(for path: String?) -> String {
        guard let path = Self.path(path) else { return "项目未提供" }
        return labels[path] ?? path
    }

    private static func path(_ value: String?) -> String? {
        guard var value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        // Pure string normalization only; never inspect the user's filesystem.
        while value.count > 1 && value.hasSuffix("/") { value.removeLast() }
        return value
    }
}

extension BoardModel {
    /// Includes hidden children even when their parent itself is hidden.
    func hiddenItems(now: Date = Date()) -> [BoardTask] {
        tasks.filter { !isVisible($0, now: now) }.sorted {
            if $0.lastActivityAt != $1.lastActivityAt { return $0.lastActivityAt > $1.lastActivityAt }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    func hiddenReason(for task: BoardTask) -> String {
        task.isConversation ? "超过24小时未活跃，且未保留显示" : "自动主体超过7天未活跃，且没有保留会话"
    }

    /// Directly preserves all affected sessions: setPinned has mutually exclusive semantics.
    /// Does not change identity, source, activity timestamps or any ownership fields.
    func restoreHiddenItem(_ id: UUID, now: Date = Date()) {
        guard let target = tasks.first(where: { $0.id == id }), !isVisible(target, now: now) else { return }
        let ids: Set<UUID>
        if target.isConversation {
            ids = [target.id]
        } else if target.isAutoGroup {
            ids = Set(children(of: target.id).filter { !isVisible($0, now: now) }.map(\.id))
        } else { return }
        var restored = tasks
        for index in restored.indices where ids.contains(restored[index].id) {
            restored[index].isPinned = true
        }
        tasks = restored
    }
}

struct HiddenRecoverySheet: View {
    @ObservedObject var model: BoardModel
    var now: Date = Date()
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var details: BoardTask?
    private var hiddenItems: [BoardTask] { model.hiddenItems(now: now) }
    private var projectLabels: RecoveryProjectLabels {
        RecoveryProjectLabels(paths: hiddenItems.map(\.projectKey))
    }
    private var matches: [BoardTask] {
        hiddenItems.filter { task in
            search.isEmpty || [task.title, task.sourceName, task.projectKey ?? ""]
                .contains { $0.localizedCaseInsensitiveContains(search) }
        }
    }
    var body: some View {
        let labels = projectLabels
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("找回已隐藏事项").font(.headline)
                Spacer()
                Button("关闭") { dismiss() }.keyboardShortcut(.cancelAction)
            }
            Text("隐藏不等于删除。保留显示会置顶该会话，也会影响共享此会话的其他主体；恢复自动主体会保留其中所有已隐藏会话，不取消其他会话的保留。")
                .font(.callout)
            TextField("搜索完整名称、来源或项目路径", text: $search)
            if matches.isEmpty { Text("没有匹配的已隐藏事项").foregroundStyle(.secondary) }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(matches) { task in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(task.title).font(.body.weight(.semibold)).textSelection(.enabled)
                            Text(task.isConversation ? task.sourceName : "自动主体")
                            Text("项目：\(labels.label(for: task.projectKey))")
                                .font(.callout).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                                .help(task.projectKey ?? "项目未提供")
                            Text(model.hiddenReason(for: task)).foregroundStyle(.secondary)
                            Text("最后活动：\(task.isConversation ? task.lastActivityAt : (model.children(of: task.id).map(\.lastActivityAt).max() ?? task.lastActivityAt), formatter: Self.dateFormatter)")
                            HStack {
                                Button("查看完整详情") { details = task }
                                Button(task.isConversation ? "保留显示" : "恢复主体及隐藏会话") {
                                    model.restoreHiddenItem(task.id, now: now)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Divider()
                    }
                }
            }
        }
        .padding(20).frame(minWidth: 480, idealWidth: 580, minHeight: 380, idealHeight: 520)
        .sheet(item: $details) { task in TaskDetailsSheet(task: task, model: model) }
    }
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}

struct TaskDetailsSheet: View {
    let task: BoardTask
    @ObservedObject var model: BoardModel
    @Environment(\.dismiss) private var dismiss
    private var current: BoardTask { model.tasks.first { $0.id == task.id } ?? task }
    private func field(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value.isEmpty ? "未提供" : value).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("完整详情").font(.headline)
                Spacer()
                Button("关闭") { dismiss() }.keyboardShortcut(.cancelAction)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    field(current.isConversation ? "会话名称" : "主体名称", current.title)
                    if current.isConversation {
                        field("来源", current.sourceName)
                        let parents = model.tasks.filter { current.belongs(to: $0.id) }.map(\.title)
                        field("所属主体", parents.joined(separator: "\n"))
                    }
                    field("项目路径", current.projectKey ?? "")
                    field("已有最后输入预览", current.lastUserPreview)
                }
            }
        }.padding(20).frame(minWidth: 460, idealWidth: 560, minHeight: 300, idealHeight: 440)
    }
}
