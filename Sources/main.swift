import AppKit
import SQLite3
import SwiftUI

enum BoardSkin: String, CaseIterable, Identifiable {
    case midnight
    case starlight
    case apple

    var id: String { rawValue }
    var title: String {
        switch self {
        case .midnight: "默认深色"
        case .starlight: "星夜电气"
        case .apple: "云白玻璃"
        }
    }

    var theme: BoardTheme {
        switch self {
        case .midnight: .midnight
        case .starlight: .starlight
        case .apple: .apple
        }
    }
}

struct BoardTheme {
    let isLight: Bool
    let background: Color
    let panel: Color
    let card: Color
    let mutedPanel: Color
    let accent: Color
    let primaryText: Color
    let secondaryText: Color
    let border: Color
    let iconBackground: Color
    let cheek: Color

    static let midnight = BoardTheme(
        isLight: false,
        background: Color(red: 0.075, green: 0.087, blue: 0.115),
        panel: Color(red: 0.11, green: 0.125, blue: 0.16),
        card: Color.white.opacity(0.055),
        mutedPanel: Color.black.opacity(0.10),
        accent: Color(red: 0.49, green: 0.65, blue: 1),
        primaryText: .white,
        secondaryText: .white.opacity(0.52),
        border: Color.white.opacity(0.14),
        iconBackground: Color(red: 0.27, green: 0.43, blue: 0.95),
        cheek: Color(red: 1, green: 0.35, blue: 0.38)
    )

    static let starlight = BoardTheme(
        isLight: false,
        background: Color(red: 0.025, green: 0.05, blue: 0.095),
        panel: Color(red: 0.055, green: 0.095, blue: 0.17),
        card: Color(red: 0.075, green: 0.13, blue: 0.23),
        mutedPanel: Color(red: 0.018, green: 0.045, blue: 0.09).opacity(0.8),
        accent: Color(red: 1.0, green: 0.82, blue: 0.22),
        primaryText: Color(red: 0.96, green: 0.98, blue: 1.0),
        secondaryText: Color(red: 0.66, green: 0.76, blue: 0.91),
        border: Color(red: 0.27, green: 0.43, blue: 0.68).opacity(0.85),
        iconBackground: Color(red: 0.31, green: 0.58, blue: 1.0),
        cheek: Color(red: 1.0, green: 0.38, blue: 0.48)
    )

    static let apple = BoardTheme(
        isLight: true,
        background: Color(red: 0.94, green: 0.96, blue: 0.985),
        panel: Color(red: 0.985, green: 0.99, blue: 1.0),
        card: Color.white.opacity(0.82),
        mutedPanel: Color(red: 0.94, green: 0.96, blue: 0.985).opacity(0.92),
        accent: Color(red: 0.04, green: 0.42, blue: 0.95),
        primaryText: Color(red: 0.10, green: 0.14, blue: 0.22),
        secondaryText: Color(red: 0.39, green: 0.45, blue: 0.54),
        border: Color(red: 0.67, green: 0.73, blue: 0.82).opacity(0.5),
        iconBackground: Color(red: 0.82, green: 0.90, blue: 1.0),
        cheek: Color(red: 1.0, green: 0.45, blue: 0.51)
    )

    func stateTint(_ state: TaskState) -> Color {
        guard isLight else { return state.tint }
        switch state {
        case .working: return Color(red: 0.02, green: 0.40, blue: 0.88)
        case .waiting: return Color(red: 0.66, green: 0.37, blue: 0.02)
        case .human: return Color(red: 0.77, green: 0.22, blue: 0.32)
        case .ready: return Color(red: 0.08, green: 0.47, blue: 0.32)
        case .done: return Color(red: 0.42, green: 0.46, blue: 0.53)
        }
    }
}

private struct BoardThemeKey: EnvironmentKey {
    static let defaultValue = BoardTheme.midnight
}

extension EnvironmentValues {
    var boardTheme: BoardTheme {
        get { self[BoardThemeKey.self] }
        set { self[BoardThemeKey.self] = newValue }
    }
}

enum TaskState: String, Codable, CaseIterable, Identifiable {
    case working = "进行中"
    case waiting = "等待 AI"
    case human = "需人工"
    case ready = "待我处理"
    case done = "已完成"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .working: "bolt.fill"
        case .waiting: "hourglass"
        case .human: "person.fill"
        case .ready: "hand.tap.fill"
        case .done: "checkmark"
        }
    }
    var tint: Color {
        switch self {
        case .working: Color(red: 0.37, green: 0.68, blue: 1)
        case .waiting: Color(red: 1, green: 0.72, blue: 0.36)
        case .human: Color(red: 1, green: 0.56, blue: 0.63)
        case .ready: Color(red: 0.48, green: 0.88, blue: 0.68)
        case .done: Color(red: 0.60, green: 0.62, blue: 0.69)
        }
    }
}

func userInputPreview(_ text: String, limit: Int = 30) -> String {
    var preview = ""
    var length = 0
    var pendingSpace = false
    for character in text {
        if character.isWhitespace {
            pendingSpace = !preview.isEmpty
            continue
        }
        if pendingSpace {
            if length == limit { return preview + "…" }
            preview.append(" ")
            length += 1
            pendingSpace = false
        }
        if length == limit { return preview + "…" }
        preview.append(character)
        length += 1
    }
    return preview
}

enum HumanActionDetector {
    static func needsHuman(_ text: String) -> Bool {
        let tail = String(text.suffix(600)).lowercased()
        let chinese = ["请你", "请您", "需要你", "需要您", "麻烦你", "请确认", "请澄清", "请说明",
                       "请提供", "请手动", "请执行", "请运行", "请登录", "请授权", "请批准",
                       "请点击", "请打开", "请上传", "请下载", "请安装", "待你确认", "需要人工"]
        if chinese.contains(where: tail.contains) { return true }
        let english = ["please confirm", "please clarify", "please provide", "please run",
                       "please execute", "please manually", "please sign in", "please approve",
                       "please authorize", "need you to", "could you confirm", "could you clarify",
                       "could you provide", "waiting for your confirmation"]
        return english.contains(where: tail.contains)
    }
}

struct BoardTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var nextStep = ""
    var link = ""
    var state: TaskState = .working
    var stateSince = Date()
    var createdAt = Date()
    var cursorPath: String? = nil
    var observedLines: Int = 0
    var qoderSessionID: String? = nil
    var qoderObservedLines: Int = 0
    var codexThreadID: String? = nil
    var lastUserPreview = ""
    var parentID: UUID? = nil
    var boundParentIDs: [UUID] = []
    var projectKey: String? = nil
    var lastActivityAt = Date()
    var isPinned = false
    var isAutoGroup = false

    var isConversation: Bool { cursorPath != nil || qoderSessionID != nil || codexThreadID != nil }
    var sourceName: String {
        if codexThreadID != nil { return "Codex" }
        return qoderSessionID != nil ? "Qoder" : "Cursor"
    }

    func belongs(to parentID: UUID) -> Bool {
        self.parentID == parentID || boundParentIDs.contains(parentID)
    }

    init(title: String) { self.title = title }

    private enum CodingKeys: String, CodingKey {
        case id, title, nextStep, link, state, stateSince, createdAt
        case cursorPath, observedLines, qoderSessionID, qoderObservedLines, codexThreadID, lastUserPreview, parentID, boundParentIDs, projectKey
        case lastActivityAt, isPinned, isAutoGroup
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try values.decode(String.self, forKey: .title)
        nextStep = try values.decodeIfPresent(String.self, forKey: .nextStep) ?? ""
        link = try values.decodeIfPresent(String.self, forKey: .link) ?? ""
        state = try values.decodeIfPresent(TaskState.self, forKey: .state) ?? .working
        stateSince = try values.decodeIfPresent(Date.self, forKey: .stateSince) ?? Date()
        createdAt = try values.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        cursorPath = try values.decodeIfPresent(String.self, forKey: .cursorPath)
        observedLines = try values.decodeIfPresent(Int.self, forKey: .observedLines) ?? 0
        qoderSessionID = try values.decodeIfPresent(String.self, forKey: .qoderSessionID)
        qoderObservedLines = try values.decodeIfPresent(Int.self, forKey: .qoderObservedLines) ?? 0
        codexThreadID = try values.decodeIfPresent(String.self, forKey: .codexThreadID)
        lastUserPreview = try values.decodeIfPresent(String.self, forKey: .lastUserPreview) ?? ""
        parentID = try values.decodeIfPresent(UUID.self, forKey: .parentID)
        boundParentIDs = try values.decodeIfPresent([UUID].self, forKey: .boundParentIDs) ?? []
        projectKey = try values.decodeIfPresent(String.self, forKey: .projectKey)
        lastActivityAt = try values.decodeIfPresent(Date.self, forKey: .lastActivityAt) ?? max(stateSince, createdAt)
        isPinned = try values.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        let legacyProjectName = projectKey.map { URL(fileURLWithPath: $0).lastPathComponent }
        isAutoGroup = try values.decodeIfPresent(Bool.self, forKey: .isAutoGroup)
            ?? (parentID == nil && !isConversation && projectKey != nil &&
                (title == legacyProjectName || title.hasPrefix("Qoder · ")))
    }
}

struct CursorSession: Identifiable {
    let path: String
    let title: String
    let lastUserPreview: String
    let modified: Date
    let lineCount: Int
    let projectKey: String
    let projectTitle: String
    var state: TaskState = .ready
    var id: String { path }
}

enum CursorReader {
    static let root = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".cursor/projects", isDirectory: true)

    static func lines(at path: String) -> [[String: Any]] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let text = String(data: data, encoding: .utf8) else { return [] }
        return text.split(separator: "\n").compactMap { line in
            guard let data = line.data(using: .utf8) else { return nil }
            return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        }
    }

    static func userText(in event: [String: Any]) -> String {
        guard event["role"] as? String == "user",
              let message = event["message"] as? [String: Any],
              let content = message["content"] as? [[String: Any]] else { return "" }
        return content.filter { $0["type"] as? String == "text" }
            .compactMap { $0["text"] as? String }.joined(separator: " ")
            .replacingOccurrences(of: "<timestamp>.*?</timestamp>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<user_query>", with: "")
            .replacingOccurrences(of: "</user_query>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func inferredState(in events: [[String: Any]]) -> TaskState {
        var lastUser = -1
        var lastCompletion = -1
        var finalReply = ""
        for (index, event) in events.enumerated() {
            if !userText(in: event).isEmpty {
                lastUser = index
                finalReply = ""
            }
            if event["role"] as? String == "assistant",
               let message = event["message"] as? [String: Any],
               let content = message["content"] as? [[String: Any]] {
                let text = content.filter { $0["type"] as? String == "text" }
                    .compactMap { $0["text"] as? String }.joined(separator: " ")
                if !text.isEmpty { finalReply = text }
            }
            if event["type"] as? String == "turn_ended" { lastCompletion = index }
        }
        if lastUser > lastCompletion { return .waiting }
        return HumanActionDetector.needsHuman(finalReply) ? .human : .ready
    }

    static func sessions() -> [CursorSession] {
        guard let projects = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { return [] }
        var found: [CursorSession] = []
        for project in projects {
            let transcripts = project.appendingPathComponent("agent-transcripts", isDirectory: true)
            let projectName = project.lastPathComponent
            let decodedPath = "/" + projectName.replacingOccurrences(of: "-", with: "/")
            let projectKey = FileManager.default.fileExists(atPath: decodedPath)
                ? URL(fileURLWithPath: decodedPath).standardizedFileURL.path
                : project.standardizedFileURL.path
            let projectTitle = FileManager.default.fileExists(atPath: decodedPath)
                ? URL(fileURLWithPath: decodedPath).lastPathComponent
                : (projectName.split(separator: "-").last.map(String.init) ?? "Cursor 项目")
            guard let agents = try? FileManager.default.contentsOfDirectory(at: transcripts, includingPropertiesForKeys: nil) else { continue }
            for agent in agents {
                let file = agent.appendingPathComponent(agent.lastPathComponent + ".jsonl")
                guard FileManager.default.fileExists(atPath: file.path) else { continue }
                let events = lines(at: file.path)
                guard let firstUser = events.first(where: { !userText(in: $0).isEmpty }) else { continue }
                let title = userText(in: firstUser)
                guard !title.isEmpty else { continue }
                let lastInput = events.reversed().lazy.map(userText(in:)).first { !$0.isEmpty } ?? title
                let attrs = try? FileManager.default.attributesOfItem(atPath: file.path)
                let modified = attrs?[.modificationDate] as? Date ?? .distantPast
                found.append(CursorSession(path: file.path, title: String(title.prefix(90)),
                                           lastUserPreview: userInputPreview(lastInput), modified: modified,
                                           lineCount: events.count, projectKey: projectKey, projectTitle: projectTitle,
                                           state: inferredState(in: events)))
            }
        }
        return found.sorted { $0.modified > $1.modified }
    }
}

struct QoderSession {
    let id: String
    let title: String
    let lastUserPreview: String
    let state: TaskState
    let lineCount: Int
    let modified: Date
    let projectKey: String
    let projectTitle: String
    let lastPromptAt: Date?
    let wasInterrupted: Bool
}

enum QoderReader {
    static let root = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".qoder/projects", isDirectory: true)

    static func timestamp(_ value: Any?) -> Date? {
        guard let text = value as? String else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: text) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: text)
    }

    static func sessions(root: URL = root) -> [QoderSession] {
        guard let projects = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { return [] }
        var found: [QoderSession] = []
        for project in projects {
            guard let files = try? FileManager.default.contentsOfDirectory(at: project, includingPropertiesForKeys: nil) else { continue }
            for file in files where file.pathExtension == "jsonl" {
                let attrs = try? FileManager.default.attributesOfItem(atPath: file.path)
                let modified = attrs?[.modificationDate] as? Date ?? .distantPast
                guard modified > Date().addingTimeInterval(-7 * 24 * 3600) else { continue }
                let events = CursorReader.lines(at: file.path)
                var title: String? = nil
                var lastInput = ""
                var lastPromptAt: Date?
                var lastPrompt = -1
                var lastCompletion = -1
                var lastCompletionText = ""
                var lastInterruption = -1
                var sessionID: String? = nil
                var cwd: String? = nil
                for (index, event) in events.enumerated() {
                    if sessionID == nil { sessionID = event["sessionId"] as? String }
                    if cwd == nil { cwd = event["cwd"] as? String }
                    guard let message = event["message"] as? [String: Any] else { continue }
                    if event["type"] as? String == "user",
                       let content = message["content"] as? [[String: Any]] {
                        let prompt = content.filter { ($0["type"] as? String) == "text" }
                            .compactMap { $0["text"] as? String }.joined(separator: " ")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        if prompt == "[Request interrupted by user]" || prompt == "[Request interrupted by user for tool use]" {
                            lastInterruption = index
                            continue
                        }
                        if !prompt.isEmpty {
                            if title == nil { title = String(prompt.prefix(90)) }
                            lastInput = prompt
                            lastPromptAt = timestamp(event["timestamp"])
                            lastPrompt = index
                        }
                    }
                    if event["type"] as? String == "assistant",
                       message["stop_reason"] as? String == "end_turn" {
                        lastCompletion = index
                        let content = message["content"] as? [[String: Any]] ?? []
                        lastCompletionText = content.filter { $0["type"] as? String == "text" }
                            .compactMap { $0["text"] as? String }.joined(separator: " ")
                    }
                }
                guard let sessionID, let title, let cwd, lastPrompt >= 0 else { continue }
                let projectPath = URL(fileURLWithPath: cwd).standardizedFileURL.path
                let leaf = URL(fileURLWithPath: projectPath).lastPathComponent
                let projectTitle = sessionID.hasPrefix(leaf) ? "Qoder · \(title)" : leaf
                found.append(QoderSession(id: sessionID, title: title,
                                          lastUserPreview: userInputPreview(lastInput),
                                          state: lastInterruption > max(lastPrompt, lastCompletion) ? .ready
                                              : lastCompletion > lastPrompt
                                                  ? (HumanActionDetector.needsHuman(lastCompletionText) ? .human : .ready)
                                                  : .waiting,
                                          lineCount: events.count, modified: modified,
                                          projectKey: projectPath, projectTitle: projectTitle,
                                          lastPromptAt: lastPromptAt,
                                          wasInterrupted: lastInterruption > max(lastPrompt, lastCompletion)))
            }
        }
        return found.sorted { $0.modified > $1.modified }
    }
}

struct CodexSession {
    let id: String
    let title: String
    let lastUserPreview: String
    let state: TaskState
    let modified: Date
    let projectKey: String
    let projectTitle: String
}

struct CodexRecentThread {
    let id: String
    let title: String
    let modified: Date
    let projectKey: String
    let rolloutPath: String
}

enum CodexReader {
    static let databaseURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".codex/state_5.sqlite")

    static func recentThreads(databaseURL: URL = databaseURL) -> [CodexRecentThread] {
        var database: OpaquePointer?
        guard sqlite3_open_v2(databaseURL.path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              let database else {
            if database != nil { sqlite3_close(database) }
            return []
        }
        defer { sqlite3_close(database) }
        sqlite3_busy_timeout(database, 100)
        let sql = """
            SELECT id, COALESCE(NULLIF(name, ''), title), cwd, rollout_path,
                   COALESCE(NULLIF(recency_at, 0), updated_at)
            FROM threads WHERE archived = 0
            ORDER BY COALESCE(NULLIF(recency_at, 0), updated_at) DESC
            """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
              let statement else { return [] }
        defer { sqlite3_finalize(statement) }
        var found: [CodexRecentThread] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let rawID = sqlite3_column_text(statement, 0),
                  let rawTitle = sqlite3_column_text(statement, 1) else { continue }
            let id = String(cString: rawID)
            let title = String(cString: rawTitle).trimmingCharacters(in: .whitespacesAndNewlines)
            guard UUID(uuidString: id) != nil, !title.isEmpty else { continue }
            let cwd = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? ""
            let projectKey = cwd.isEmpty
                ? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex").path
                : URL(fileURLWithPath: cwd).standardizedFileURL.path
            let rolloutPath = sqlite3_column_text(statement, 3).map { String(cString: $0) } ?? ""
            let modified = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 4)))
            found.append(CodexRecentThread(id: id, title: String(title.prefix(90)),
                                           modified: modified, projectKey: projectKey,
                                           rolloutPath: rolloutPath))
        }
        return found
    }

    static func recentActivity(at path: String) -> (TaskState, String)? {
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        let activity = latestActivity(at: path)
        return (activity.state, activity.lastUserPreview)
    }

    private struct Activity {
        let state: TaskState
        let lastUserPreview: String
    }

    private struct CachedState {
        let size: Int
        let modified: Date
        let activity: Activity
    }
    private static var stateCache: [String: CachedState] = [:]

    static func sessions(databaseURL: URL = databaseURL, now: Date = Date()) -> [CodexSession] {
        var database: OpaquePointer?
        guard sqlite3_open_v2(databaseURL.path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              let database else {
            if database != nil { sqlite3_close(database) }
            return []
        }
        defer { sqlite3_close(database) }
        sqlite3_busy_timeout(database, 100)
        let sql = """
            SELECT id, COALESCE(NULLIF(name, ''), title), cwd, rollout_path, updated_at
            FROM threads
            WHERE archived = 0 AND updated_at >= ?
            ORDER BY updated_at DESC LIMIT 200
            """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
              let statement else { return [] }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_int64(statement, 1, Int64(now.addingTimeInterval(-7 * 86400).timeIntervalSince1970))
        var found: [CodexSession] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let rawID = sqlite3_column_text(statement, 0),
                  let rawTitle = sqlite3_column_text(statement, 1),
                  let rawRollout = sqlite3_column_text(statement, 3) else { continue }
            let id = String(cString: rawID)
            let title = String(cString: rawTitle).trimmingCharacters(in: .whitespacesAndNewlines)
            let rolloutPath = String(cString: rawRollout)
            guard !id.isEmpty, !title.isEmpty else { continue }
            let cwd = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? ""
            let projectPath = cwd.isEmpty
                ? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex").path
                : URL(fileURLWithPath: cwd).standardizedFileURL.path
            let projectTitle = cwd.isEmpty ? "Codex" : URL(fileURLWithPath: projectPath).lastPathComponent
            let databaseModified = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 4)))
            let attrs = try? FileManager.default.attributesOfItem(atPath: rolloutPath)
            let fileModified = attrs?[.modificationDate] as? Date ?? .distantPast
            let modified = min(max(databaseModified, fileModified), now)
            let activity = latestActivity(at: rolloutPath)
            found.append(CodexSession(id: id, title: String(title.prefix(90)),
                                      lastUserPreview: activity.lastUserPreview,
                                      state: activity.state, modified: modified,
                                      projectKey: projectPath, projectTitle: projectTitle))
        }
        return found
    }

    private static func latestActivity(at path: String) -> Activity {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attrs[.size] as? Int,
              let modified = attrs[.modificationDate] as? Date else {
            return Activity(state: .working, lastUserPreview: "")
        }
        if let cached = stateCache[path], cached.size == size, cached.modified == modified {
            return cached.activity
        }
        let activity = scanLatestActivity(at: path, size: size)
        stateCache[path] = CachedState(size: size, modified: modified, activity: activity)
        return activity
    }

    private static func scanLatestActivity(at path: String, size: Int) -> Activity {
        let fallback = Activity(state: .working, lastUserPreview: "")
        guard size > 0,
              let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) else { return fallback }
        var state: TaskState?
        var lastInput: String?
        var completionStart: Int?
        let stateMarkers = ["task_started", "task_complete", "turn_aborted"].map { Data($0.utf8) }
        var stateEnd = data.endIndex
        while state == nil, let match = latestRange(of: stateMarkers, in: data, before: stateEnd) {
            state = eventState(in: line(containing: match, in: data))
            if state == .ready { completionStart = match.lowerBound }
            stateEnd = match.lowerBound
        }
        let userMarker = Data("\"role\":\"user\"".utf8)
        var userEnd = data.endIndex
        var lastUserStart = data.startIndex
        while lastInput == nil,
              let match = data.range(of: userMarker, options: .backwards, in: data.startIndex..<userEnd) {
            lastInput = userText(in: line(containing: match, in: data))
            if lastInput != nil { lastUserStart = match.lowerBound }
            userEnd = match.lowerBound
        }
        if let completionStart, lastUserStart < completionStart {
            let assistantMarker = Data("\"role\":\"assistant\"".utf8)
            var assistantEnd = completionStart
            while let match = data.range(of: assistantMarker, options: .backwards,
                                         in: lastUserStart..<assistantEnd) {
                if let reply = assistantText(in: line(containing: match, in: data)) {
                    if HumanActionDetector.needsHuman(reply) { state = .human }
                    break
                }
                assistantEnd = match.lowerBound
            }
        }
        return Activity(state: state ?? .working, lastUserPreview: lastInput ?? "")
    }

    private static func latestRange(of markers: [Data], in data: Data, before end: Int) -> Range<Int>? {
        markers.compactMap { data.range(of: $0, options: .backwards, in: data.startIndex..<end) }
            .max { $0.lowerBound < $1.lowerBound }
    }

    private static func line(containing match: Range<Int>, in data: Data) -> Data.SubSequence {
        let start = data[..<match.lowerBound].lastIndex(of: 10).map { $0 + 1 } ?? data.startIndex
        let end = data[match.upperBound...].firstIndex(of: 10) ?? data.endIndex
        return data[start..<end]
    }

    private static func userText(in line: Data.SubSequence) -> String? {
        guard line.range(of: Data("\"type\":\"response_item\"".utf8)) != nil,
              line.range(of: Data("\"role\":\"user\"".utf8)) != nil,
              let event = (try? JSONSerialization.jsonObject(with: Data(line))) as? [String: Any],
              let payload = event["payload"] as? [String: Any],
              payload["type"] as? String == "message",
              payload["role"] as? String == "user",
              let content = payload["content"] as? [[String: Any]] else { return nil }
        let text = content.filter { $0["type"] as? String == "input_text" }
            .compactMap { $0["text"] as? String }.joined(separator: " ")
        if text.hasPrefix("<environment_context>") { return nil }
        let authoredText: String
        if text.hasPrefix("# Files mentioned by the user:"),
           let request = text.range(of: "## My request:") {
            authoredText = String(text[request.upperBound...])
        } else {
            authoredText = text
        }
        let preview = userInputPreview(authoredText)
        return preview.isEmpty ? nil : preview
    }

    private static func assistantText(in line: Data.SubSequence) -> String? {
        guard line.range(of: Data("\"type\":\"response_item\"".utf8)) != nil,
              let event = (try? JSONSerialization.jsonObject(with: Data(line))) as? [String: Any],
              let payload = event["payload"] as? [String: Any],
              payload["type"] as? String == "message",
              payload["role"] as? String == "assistant",
              let content = payload["content"] as? [[String: Any]] else { return nil }
        let reply = content.filter { $0["type"] as? String == "output_text" }
            .compactMap { $0["text"] as? String }.joined(separator: " ")
        return reply.isEmpty ? nil : reply
    }

    private static func eventState(in line: Data.SubSequence) -> TaskState? {
        guard line.range(of: Data("\"type\":\"event_msg\"".utf8)) != nil,
              (line.range(of: Data("task_started".utf8)) != nil ||
               line.range(of: Data("task_complete".utf8)) != nil ||
               line.range(of: Data("turn_aborted".utf8)) != nil),
              let event = (try? JSONSerialization.jsonObject(with: Data(line))) as? [String: Any],
              let payload = event["payload"] as? [String: Any],
              let eventType = payload["type"] as? String else { return nil }
        switch eventType {
        case "task_started": return .waiting
        case "task_complete": return .ready
        case "turn_aborted": return .working
        default: return nil
        }
    }
}

final class BoardModel: ObservableObject {
    @Published var tasks: [BoardTask] = [] {
        didSet { save() }
    }
    @Published private(set) var codexRecentThreads: [CodexRecentThread] = []
    @Published private(set) var isLoadingCodexRecent = false
    @Published private(set) var hasLoadedCodexRecent = false

    private let fileURL: URL
    private let qoderEventsURL: URL

    init(dataDirectory: URL? = nil) {
        let support = dataDirectory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DeskFocusBoard", isDirectory: true)
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        fileURL = support.appendingPathComponent("tasks.json")
        qoderEventsURL = support.appendingPathComponent("qoder-events.jsonl")
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([BoardTask].self, from: data) {
            let repaired = Self.normalizedAutoGroups(saved)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            if (try? encoder.encode(saved)) != (try? encoder.encode(repaired)) {
                let backup = support.appendingPathComponent("tasks-before-auto-group-repair.json")
                do {
                    if !FileManager.default.fileExists(atPath: backup.path) {
                        try FileManager.default.copyItem(at: fileURL, to: backup)
                    }
                    tasks = repaired
                    save()
                } catch {
                    // Keep original ownership if a recovery copy cannot be created.
                    tasks = saved
                }
            } else {
                tasks = saved
            }
        } else if FileManager.default.fileExists(atPath: fileURL.path) {
            let recovery = support.appendingPathComponent("tasks-unreadable-recovery.json")
            if !FileManager.default.fileExists(atPath: recovery.path) {
                try? FileManager.default.copyItem(at: fileURL, to: recovery)
            }
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        let backup = fileURL.deletingLastPathComponent().appendingPathComponent("tasks.json.bak")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.copyItem(at: fileURL, to: backup)
        }
        try? data.write(to: fileURL, options: .atomic)
    }

    func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.insert(BoardTask(title: trimmed), at: 0)
    }

    func renameTask(_ id: UUID, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        update(id) { $0.title = trimmed }
    }

    func update(_ id: UUID, _ change: (inout BoardTask) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        change(&tasks[index])
    }

    func setState(_ id: UUID, to state: TaskState) {
        if state == .done, let task = tasks.first(where: { $0.id == id }), !task.isConversation {
            for index in tasks.indices where tasks[index].parentID == id {
                tasks[index].state = .done
                tasks[index].stateSince = Date()
            }
        }
        update(id) { task in
            guard task.state != state else { return }
            task.state = state
            task.stateSince = Date()
        }
    }

    func remove(_ id: UUID) {
        for index in tasks.indices {
            if tasks[index].parentID == id { tasks[index].parentID = nil }
            tasks[index].boundParentIDs.removeAll { $0 == id }
        }
        tasks.removeAll { $0.id == id }
    }

    func assignParent(_ childID: UUID, to parentID: UUID?) {
        guard let child = tasks.first(where: { $0.id == childID }), child.isConversation else { return }
        if let parentID {
            guard let parent = tasks.first(where: { $0.id == parentID && $0.parentID == nil && !$0.isConversation && $0.state != .done }),
                  parent.projectKey == nil || parent.projectKey == child.projectKey else { return }
            if parent.projectKey == nil { update(parentID) { $0.projectKey = child.projectKey } }
            if child.isPinned {
                for index in tasks.indices where tasks[index].parentID == parentID {
                    tasks[index].isPinned = false
                }
            }
        }
        update(childID) { task in
            task.parentID = parentID
            task.boundParentIDs.removeAll()
        }
        save()
    }

    func bindSession(_ childID: UUID, to parentID: UUID) {
        guard tasks.contains(where: { $0.id == parentID && $0.parentID == nil && !$0.isConversation }) else { return }
        if !tasks.contains(where: { $0.id == childID }),
           let recent = codexRecentThreads.first(where: { UUID(uuidString: $0.id) == childID }) {
            var child = BoardTask(title: recent.title)
            child.codexThreadID = recent.id
            child.lastUserPreview = userInputPreview(recent.title)
            child.projectKey = recent.projectKey
            child.lastActivityAt = recent.modified
            child.state = .ready
            child.isPinned = Date().timeIntervalSince(recent.modified) >= 24 * 3600
            child.boundParentIDs = [parentID]
            tasks.insert(child, at: 0)
            let newID = child.id
            let initialStateSince = child.stateSince
            DispatchQueue.global(qos: .utility).async { [weak self] in
                guard let activity = CodexReader.recentActivity(at: recent.rolloutPath) else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.update(newID) { task in
                        if task.stateSince == initialStateSince {
                            task.state = activity.0
                            task.stateSince = recent.modified
                        }
                        if !activity.1.isEmpty { task.lastUserPreview = activity.1 }
                    }
                }
            }
            return
        }
        guard let child = tasks.first(where: { $0.id == childID }), child.isConversation else { return }
        update(childID) { task in
            guard !task.belongs(to: parentID) else { return }
            task.boundParentIDs.append(parentID)
            if Date().timeIntervalSince(task.lastActivityAt) >= 24 * 3600 { task.isPinned = true }
        }
        save()
    }

    func unbindSession(_ childID: UUID, from parentID: UUID) {
        guard let child = tasks.first(where: { $0.id == childID }), child.isConversation else { return }
        update(childID) { task in
            if task.parentID == parentID {
                task.parentID = task.boundParentIDs.first
                if !task.boundParentIDs.isEmpty { task.boundParentIDs.removeFirst() }
            } else {
                task.boundParentIDs.removeAll { $0 == parentID }
            }
        }
        save()
    }

    func bindableSessions(for parentID: UUID) -> [BoardTask] {
        let importedIDs = Set(tasks.compactMap(\.codexThreadID))
        let recentCandidates = codexRecentThreads.compactMap { recent -> BoardTask? in
            guard !importedIDs.contains(recent.id), let id = UUID(uuidString: recent.id) else { return nil }
            var candidate = BoardTask(title: recent.title)
            candidate.id = id
            candidate.codexThreadID = recent.id
            candidate.lastUserPreview = userInputPreview(recent.title)
            candidate.projectKey = recent.projectKey
            candidate.lastActivityAt = recent.modified
            candidate.state = .ready
            return candidate
        }
        return (tasks.filter { $0.isConversation && !$0.belongs(to: parentID) } + recentCandidates)
            .sorted {
                if $0.lastActivityAt != $1.lastActivityAt { return $0.lastActivityAt > $1.lastActivityAt }
                return $0.id.uuidString < $1.id.uuidString
            }
    }

    func loadCodexRecentForBinding() {
        guard !isLoadingCodexRecent else { return }
        isLoadingCodexRecent = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let recent = CodexReader.recentThreads()
            DispatchQueue.main.async { [weak self] in
                self?.setCodexRecentForBinding(recent)
                self?.isLoadingCodexRecent = false
            }
        }
    }

    func setCodexRecentForBinding(_ recent: [CodexRecentThread]) {
        codexRecentThreads = recent
        hasLoadedCodexRecent = true
    }

    func parentCandidates(for child: BoardTask) -> [BoardTask] {
        tasks.filter { $0.parentID == nil && !$0.isConversation && $0.state != .done &&
            ($0.projectKey == nil || $0.projectKey == child.projectKey) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Consolidate only automatic ownership; explicit manual bindings remain intact.
    static func normalizedAutoGroups(_ original: [BoardTask]) -> [BoardTask] {
        var result = original
        let automatic = original.filter { $0.isAutoGroup && !$0.isConversation && $0.projectKey?.isEmpty == false }
        let oldIDs = Set(automatic.map(\.id))
        var byKey = Dictionary(grouping: automatic, by: { $0.projectKey! })
        for child in original where child.isConversation {
            guard let parent = child.parentID, oldIDs.contains(parent),
                  let key = child.projectKey, !key.isEmpty, byKey[key] == nil else { continue }
            var group = BoardTask(title: URL(fileURLWithPath: key).lastPathComponent)
            group.projectKey = key
            group.isAutoGroup = true
            group.createdAt = child.createdAt
            group.lastActivityAt = child.lastActivityAt
            group.state = child.state
            byKey[key] = [group]
            result.append(group)
        }
        var destinations: [String: UUID] = [:]
        var replacements: [UUID: UUID] = [:]
        var removed = Set<UUID>()
        for key in byKey.keys.sorted() {
            let groups = byKey[key]!.sorted {
                if ($0.state == .done) != ($1.state == .done) { return $0.state != .done }
                if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
                return $0.id.uuidString < $1.id.uuidString
            }
            let canonical = groups[0]
            destinations[key] = canonical.id
            for group in groups { replacements[group.id] = canonical.id }
            guard let index = result.firstIndex(where: { $0.id == canonical.id }) else { continue }
            result[index].title = URL(fileURLWithPath: key).lastPathComponent
            result[index].isPinned = groups.contains { $0.isPinned }
            for group in groups.dropFirst() {
                removed.insert(group.id)
                // Preserve any notes or saved links on a merged automatic group.
                for note in [group.nextStep, group.link] where !note.isEmpty {
                    if !result[index].nextStep.contains(note) {
                        result[index].nextStep += (result[index].nextStep.isEmpty ? "" : "\n") + note
                    }
                }
            }
        }
        for index in result.indices where result[index].isConversation {
            if let parent = result[index].parentID, oldIDs.contains(parent),
               let key = result[index].projectKey, let destination = destinations[key] {
                result[index].parentID = destination
            }
            var seen = Set<UUID>()
            result[index].boundParentIDs = result[index].boundParentIDs
                .map { replacements[$0] ?? $0 }
                .filter { $0 != result[index].parentID && seen.insert($0).inserted }
        }
        result.removeAll { removed.contains($0.id) }
        return result
    }

    private func ensureProjectParent(for childID: UUID, key: String, title: String) {
        guard !key.isEmpty, let child = tasks.first(where: { $0.id == childID }) else { return }
        if let parentID = child.parentID,
           let parent = tasks.first(where: { $0.id == parentID }), !parent.isAutoGroup { return }
        if child.parentID == nil && !child.boundParentIDs.isEmpty { return }
        let parentID: UUID
        if let existing = tasks.first(where: { $0.isAutoGroup && !$0.isConversation && $0.projectKey == key }) {
            parentID = existing.id
        } else {
            var parent = BoardTask(title: URL(fileURLWithPath: key).lastPathComponent)
            parent.projectKey = key
            parent.isAutoGroup = true
            parentID = parent.id
            tasks.insert(parent, at: 0)
        }
        if child.projectKey != key || child.parentID != parentID {
            update(childID) { task in
                task.projectKey = key
                task.parentID = parentID
            }
        }
    }

    func children(of id: UUID) -> [BoardTask] {
        tasks.filter { $0.belongs(to: id) }.sorted(by: sessionOrder)
    }

    private func sessionOrder(_ lhs: BoardTask, _ rhs: BoardTask) -> Bool {
        if lhs.lastActivityAt != rhs.lastActivityAt { return lhs.lastActivityAt > rhs.lastActivityAt }
        if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    func visibleChildren(of id: UUID, now: Date = Date()) -> [BoardTask] {
        children(of: id).filter { $0.isPinned || now.timeIntervalSince($0.lastActivityAt) < 24 * 3600 }
    }

    func latestActivityDate(for task: BoardTask, now: Date = Date()) -> Date {
        if task.isConversation { return task.lastActivityAt }
        return visibleChildren(of: task.id, now: now).map(\.lastActivityAt).max() ?? task.lastActivityAt
    }

    func setPinned(_ id: UUID) {
        guard let target = tasks.first(where: { $0.id == id }), target.isConversation else { return }
        let nextValue = !target.isPinned
        for index in tasks.indices where tasks[index].isConversation &&
            (target.parentID == nil ? tasks[index].id == id : tasks[index].parentID == target.parentID) {
            tasks[index].isPinned = nextValue && tasks[index].id == id
        }
    }

    func toggleTaskStar(_ id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isPinned.toggle()
        save()
    }

    func navigationTarget(for task: BoardTask, now: Date = Date()) -> BoardTask? {
        if task.isConversation { return task }
        return visibleChildren(of: task.id, now: now).first
    }

    func directURL(for task: BoardTask) -> URL? {
        let trimmed = task.link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(),
              ["http", "https", "qoder", "qoder-app", "cursor", "codex"].contains(scheme),
              !["http", "https"].contains(scheme) || url.host != nil else { return nil }
        return url
    }

    func openConversation(for task: BoardTask, now: Date = Date()) {
        guard let target = navigationTarget(for: task, now: now) else { return }
        let trimmed = target.link.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            guard let url = directURL(for: target), NSWorkspace.shared.open(url) else {
                return
            }
            return
        }
        if let threadID = target.codexThreadID,
           let url = URL(string: "codex://threads/\(threadID)"),
           NSWorkspace.shared.open(url) { return }
        if let sessionID = target.qoderSessionID {
            QoderDesktopNavigator.shared.open(id: sessionID)
            return
        }
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier:
            target.codexThreadID != nil ? "com.openai.codex" :
                (target.qoderSessionID == nil ? "com.todesktop.230313mzl4w4u92" : "com.qoder.app")) else { return }
        NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
    }

    func isVisible(_ task: BoardTask, now: Date = Date()) -> Bool {
        if task.isConversation { return task.isPinned || now.timeIntervalSince(task.lastActivityAt) < 24 * 3600 }
        guard task.isAutoGroup else { return true }
        let sessions = children(of: task.id)
        if sessions.contains(where: \.isPinned) { return true }
        guard let latest = sessions.map(\.lastActivityAt).max() else { return true }
        return now.timeIntervalSince(latest) < 7 * 24 * 3600
    }

    func displayState(for task: BoardTask) -> TaskState {
        let children = visibleChildren(of: task.id).filter { $0.state != .done }
        if children.contains(where: { $0.state == .human }) { return .human }
        if task.state == .human { return .human }
        if children.contains(where: { $0.state == .ready }) { return .ready }
        if task.state == .ready { return .ready }
        if children.contains(where: { $0.state == .working }) { return .working }
        if children.contains(where: { $0.state == .waiting }) { return .waiting }
        return task.state
    }

    func summarySessionCount(for task: BoardTask, now: Date = Date()) -> Int {
        let state = displayState(for: task)
        let sessions = task.isConversation ? [task] : visibleChildren(of: task.id, now: now)
        return sessions.filter { $0.state == state }.count
    }

    func importCursor(_ session: CursorSession) {
        guard !tasks.contains(where: { $0.cursorPath == session.path }) else { return }
        var task = BoardTask(title: session.title)
        task.cursorPath = session.path
        task.lastUserPreview = session.lastUserPreview
        task.projectKey = session.projectKey
        task.observedLines = session.lineCount
        task.state = session.state
        task.lastActivityAt = min(session.modified, Date())
        tasks.insert(task, at: 0)
        ensureProjectParent(for: task.id, key: session.projectKey, title: session.projectTitle)
    }

    func pollCursor() {
        let sessions = Dictionary(uniqueKeysWithValues: CursorReader.sessions().map { ($0.path, $0) })
        for task in tasks where task.cursorPath != nil {
            guard let path = task.cursorPath, let session = sessions[path] else { continue }
            if task.lastUserPreview != session.lastUserPreview {
                update(task.id) { $0.lastUserPreview = session.lastUserPreview }
            }
            if task.projectKey != session.projectKey {
                update(task.id) { $0.projectKey = session.projectKey }
            }
            ensureProjectParent(for: task.id, key: session.projectKey, title: session.projectTitle)
        }
        for index in tasks.indices {
            guard let path = tasks[index].cursorPath else { continue }
            let events = CursorReader.lines(at: path)
            let oldCount = tasks[index].observedLines
            guard events.count > oldCount else { continue }
            let nextState = CursorReader.inferredState(in: events)
            tasks[index].observedLines = events.count
            tasks[index].lastActivityAt = min(sessions[path]?.modified ?? Date(), Date())
            if tasks[index].state != .done, tasks[index].state != nextState {
                tasks[index].state = nextState
                tasks[index].stateSince = Date()
            }
        }
    }

    func pollQoder(defaults: UserDefaults = .standard) {
        let events = CursorReader.lines(at: qoderEventsURL.path)
        let savedCount = defaults.integer(forKey: "qoderEventLineCount")
        let oldCount = events.count < savedCount ? 0 : savedCount
        guard events.count > oldCount else { return }
        for event in events.dropFirst(oldCount) {
            guard let sessionID = event["session_id"] as? String, !sessionID.isEmpty,
                  let eventName = event["hook_event_name"] as? String else { continue }
            let nextState: TaskState
            switch eventName {
            case "UserPromptSubmit": nextState = .waiting
            case "Stop": nextState = .ready
            default: continue
            }
            let childID: UUID
            if let existing = tasks.firstIndex(where: { $0.qoderSessionID == sessionID }) {
                childID = tasks[existing].id
            } else {
                let preview = (event["prompt_preview"] as? String ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let cwd = event["cwd"] as? String ?? ""
                let projectName = URL(fileURLWithPath: cwd).lastPathComponent
                let title = preview.isEmpty ? "Qoder · \(projectName.isEmpty ? "新对话" : projectName)" : preview
                var task = BoardTask(title: title)
                task.qoderSessionID = sessionID
                task.lastUserPreview = userInputPreview(preview)
                task.projectKey = URL(fileURLWithPath: cwd).standardizedFileURL.path
                task.state = nextState
                task.stateSince = Date()
                tasks.insert(task, at: 0)
                childID = task.id
            }
            if let child = tasks.first(where: { $0.id == childID }), let key = child.projectKey, !key.isEmpty {
                ensureProjectParent(for: childID, key: key,
                                    title: URL(fileURLWithPath: key).lastPathComponent)
            }
            guard let index = tasks.firstIndex(where: { $0.id == childID }) else { continue }
            if eventName == "UserPromptSubmit",
               let preview = event["prompt_preview"] as? String, !preview.isEmpty {
                tasks[index].lastUserPreview = userInputPreview(preview)
            }
            let promptTime = QoderReader.timestamp(event["timestamp"]) ?? Date()
            let newPrompt = eventName == "UserPromptSubmit" && promptTime > tasks[index].stateSince
            if (tasks[index].state != .done || newPrompt), tasks[index].state != nextState {
                tasks[index].state = nextState
                tasks[index].stateSince = Date()
            }
            tasks[index].lastActivityAt = Date()
        }
        defaults.set(events.count, forKey: "qoderEventLineCount")
    }

    func pollQoderTranscripts(root: URL = QoderReader.root) {
        for session in QoderReader.sessions(root: root) {
            if let existing = tasks.firstIndex(where: { $0.qoderSessionID == session.id }) {
                let childID = tasks[existing].id
                if tasks[existing].projectKey != session.projectKey {
                    tasks[existing].projectKey = session.projectKey
                }
                ensureProjectParent(for: childID, key: session.projectKey, title: session.projectTitle)
                guard let index = tasks.firstIndex(where: { $0.id == childID }) else { continue }
                if tasks[index].lastUserPreview != session.lastUserPreview {
                    tasks[index].lastUserPreview = session.lastUserPreview
                }
                let hasNewPrompt = session.lastPromptAt.map { $0 > tasks[index].stateSince } ?? false
                let missedInterruption = session.wasInterrupted && tasks[index].state == .waiting
                    && tasks[index].lastActivityAt <= session.modified
                guard session.lineCount != tasks[index].qoderObservedLines
                        || (tasks[index].state == .done && hasNewPrompt) || missedInterruption else { continue }
                tasks[index].qoderObservedLines = session.lineCount
                tasks[index].lastActivityAt = min(session.modified, Date())
                if (tasks[index].state != .done || hasNewPrompt), tasks[index].state != session.state {
                    tasks[index].state = session.state
                    tasks[index].stateSince = Date()
                }
            } else {
                var task = BoardTask(title: session.title)
                task.qoderSessionID = session.id
                task.lastUserPreview = session.lastUserPreview
                task.projectKey = session.projectKey
                task.qoderObservedLines = session.lineCount
                task.state = session.state
                task.stateSince = session.modified
                task.lastActivityAt = min(session.modified, Date())
                tasks.insert(task, at: 0)
                ensureProjectParent(for: task.id, key: session.projectKey, title: session.projectTitle)
            }
        }
    }

    func mergeCodex(_ sessions: [CodexSession]) {
        for session in sessions {
            if let index = tasks.firstIndex(where: { $0.codexThreadID == session.id }) {
                let childID = tasks[index].id
                if tasks[index].projectKey != session.projectKey {
                    tasks[index].projectKey = session.projectKey
                }
                ensureProjectParent(for: childID, key: session.projectKey, title: session.projectTitle)
                guard let current = tasks.firstIndex(where: { $0.id == childID }) else { continue }
                if tasks[current].lastUserPreview != session.lastUserPreview {
                    tasks[current].lastUserPreview = session.lastUserPreview
                }
                if session.modified > tasks[current].lastActivityAt {
                    tasks[current].lastActivityAt = session.modified
                    if tasks[current].state != .done && tasks[current].state != session.state {
                        tasks[current].state = session.state
                        tasks[current].stateSince = session.modified
                    }
                }
            } else {
                var task = BoardTask(title: session.title)
                task.codexThreadID = session.id
                task.lastUserPreview = session.lastUserPreview
                task.projectKey = session.projectKey
                task.state = session.state
                task.stateSince = session.modified
                task.lastActivityAt = session.modified
                tasks.insert(task, at: 0)
                ensureProjectParent(for: task.id, key: session.projectKey, title: session.projectTitle)
            }
        }
    }

    var active: [BoardTask] {
        tasks.filter { $0.parentID == nil && $0.boundParentIDs.isEmpty && isVisible($0) && displayState(for: $0) != .done }.sorted {
            let firstActivity = latestActivityDate(for: $0)
            let secondActivity = latestActivityDate(for: $1)
            if firstActivity != secondActivity { return firstActivity > secondActivity }
            return $0.createdAt > $1.createdAt
        }
    }
    var completed: [BoardTask] { tasks.filter { $0.parentID == nil && $0.boundParentIDs.isEmpty && isVisible($0) && displayState(for: $0) == .done }.sorted { $0.stateSince > $1.stateSince } }
}

struct StarlightBackdrop: View {
    let theme: BoardTheme

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RadialGradient(
                    colors: [theme.iconBackground.opacity(0.20), .clear],
                    center: .topTrailing,
                    startRadius: 5,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.95
                )
                VStack {
                    HStack {
                        Spacer()
                        StarlightArtwork.image(named: "starlight-mascot")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 158, height: 98)
                            .opacity(0.48)
                            .offset(x: 9, y: -13)
                    }
                    Spacer()
                    StarlightArtwork.image(named: "starlight-clouds")
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: 125, alignment: .bottom)
                        .clipped()
                        .opacity(0.82)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct AppleBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.965, green: 0.978, blue: 1),
                             Color(red: 0.91, green: 0.945, blue: 0.99),
                             Color(red: 0.955, green: 0.965, blue: 0.985)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(Color(red: 0.67, green: 0.82, blue: 1).opacity(0.34))
                    .frame(width: 280, height: 280)
                    .blur(radius: 75)
                    .position(x: proxy.size.width, y: 20)
                Circle()
                    .fill(Color(red: 0.85, green: 0.79, blue: 1).opacity(0.20))
                    .frame(width: 240, height: 240)
                    .blur(radius: 85)
                    .position(x: 0, y: proxy.size.height)
            }
        }
        .allowsHitTesting(false)
    }
}

struct AppleOrbitMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(LinearGradient(
                    colors: [.white, Color(red: 0.88, green: 0.94, blue: 1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            Circle()
                .trim(from: 0.08, to: 0.88)
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 0.12, green: 0.57, blue: 1),
                                 Color(red: 0.02, green: 0.35, blue: 0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 2.8, lineCap: .round)
                )
                .frame(width: 18, height: 18)
                .rotationEffect(.degrees(-50))
            Circle()
                .fill(Color(red: 0.03, green: 0.39, blue: 0.91))
                .frame(width: 5, height: 5)
                .offset(x: 8, y: -8)
        }
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
            .stroke(.white.opacity(0.95), lineWidth: 1))
        .shadow(color: Color(red: 0.25, green: 0.46, blue: 0.77).opacity(0.16), radius: 5, y: 2)
        .accessibilityLabel("Orbit 图标")
    }
}

enum StarlightArtwork {
    static func image(named name: String) -> Image {
        let path = Bundle.main.path(forResource: name, ofType: "png") ?? ""
        return Image(nsImage: NSImage(contentsOfFile: path) ?? NSImage())
    }
}

struct BoardView: View {
    @ObservedObject var model: BoardModel
    @AppStorage("deskfocus.skin") private var skinRaw = BoardSkin.midnight.rawValue
    @State private var newTitle = ""
    @State private var showCompleted = false
    @State private var showNewTaskField = false
    @State private var showStarredOnly = false
    @State private var now = Date()

    private var skin: BoardSkin { BoardSkin(rawValue: skinRaw) ?? .midnight }
    private var theme: BoardTheme { skin.theme }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(theme.border.opacity(0.55))
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if showNewTaskField { newTaskRow }
                    let activeTasks = filtered(model.active)
                    let completedTasks = filtered(model.completed)
                    if activeTasks.isEmpty {
                        emptyState
                    } else {
                        HStack {
                            Text("当前事项").font(.system(size: 12, weight: .semibold)).foregroundStyle(theme.secondaryText)
                            Spacer()
                            Text("\(activeTasks.count) 件").font(.system(size: 11, weight: .medium)).foregroundStyle(theme.secondaryText.opacity(0.82))
                        }
                        .padding(.horizontal, 2)
                        ForEach(activeTasks) { task in
                            TaskCard(task: task, model: model, now: now)
                        }
                    }
                    if !completedTasks.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) { showCompleted.toggle() }
                        } label: {
                            HStack {
                                Image(systemName: showCompleted ? "chevron.down" : "chevron.right")
                            Text("已完成 · \(completedTasks.count)")
                                Spacer()
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(theme.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 6)
                        if showCompleted {
                            ForEach(completedTasks) { task in
                                TaskCard(task: task, model: model, now: now)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            Divider().overlay(theme.border.opacity(0.55))
            footer
        }
        .background {
            ZStack(alignment: .bottom) {
                theme.background
                if skin == .starlight {
                    StarlightBackdrop(theme: theme)
                } else if skin == .apple {
                    AppleBackdrop()
                }
            }
        }
        .frame(minWidth: 350, minHeight: 430)
        .preferredColorScheme(theme.isLight ? .light : .dark)
        .environment(\.boardTheme, theme)
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { now = $0 }
    }

    private var header: some View {
        HStack(spacing: 9) {
            if skin == .apple {
                AppleOrbitMark().frame(width: 32, height: 32)
            } else {
                StarlightArtwork.image(named: "orbit-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .accessibilityLabel("Orbit 图标")
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text("Orbit")
                        .font(.system(size: skin == .apple ? 16 : 15,
                                      weight: skin == .apple ? .semibold : .bold,
                                      design: skin == .apple ? .rounded : .default))
                        .tracking(skin == .apple ? -0.4 : 0)
                        .foregroundStyle(theme.primaryText)
                    Button { showNewTaskField.toggle() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.accent)
                            .frame(width: 26, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("新增主体任务")
                }
                Text(skin == .starlight ? "在星光下抓住灵感 ⚡" : "多线程工作，一眼看清")
                    .font(.system(size: 10)).foregroundStyle(theme.secondaryText.opacity(0.9))
            }
            Spacer()
            Menu {
                ForEach(BoardSkin.allCases) { option in
                    Button {
                        selectSkin(option)
                    } label: {
                        HStack {
                            Text(option.title)
                            if option == skin { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                Image(systemName: "paintpalette")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.secondaryText)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .help("切换皮肤")
            Button { showStarredOnly.toggle() } label: {
                Image(systemName: showStarredOnly ? "star.fill" : "star")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(showStarredOnly ? theme.accent : theme.secondaryText)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(showStarredOnly ? "显示全部事项" : "只看星标")
            let actionCount = model.active.filter { [.human, .ready].contains(model.displayState(for: $0)) }.count
            let hasHumanAction = model.active.contains { model.displayState(for: $0) == .human }
            if actionCount > 0 {
                Text("\(actionCount) 件待处理")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(theme.stateTint(hasHumanAction ? .human : .ready))
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(theme.stateTint(hasHumanAction ? .human : .ready).opacity(0.12), in: Capsule())
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var newTaskRow: some View {
        HStack(spacing: 8) {
            TextField("新增主体任务…", text: $newTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onSubmit(addTask)
            if !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button("添加", action: addTask)
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.accent)
            }
        }
        .padding(.horizontal, 13).padding(.vertical, 10)
        .background(theme.card, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.border.opacity(0.55)))
    }

    private func addTask() {
        model.add(newTitle)
        newTitle = ""
        showNewTaskField = false
    }

    private func selectSkin(_ option: BoardSkin) {
        skinRaw = option.rawValue
        for window in NSApp.windows where window.title == "Orbit" {
            window.appearance = NSAppearance(named: option == .apple ? .aqua : .darkAqua)
            window.backgroundColor = option == .apple
                ? NSColor(red: 0.965, green: 0.978, blue: 1, alpha: 1)
                : NSColor(red: 0.075, green: 0.087, blue: 0.115, alpha: 1)
        }
    }

    private func filtered(_ tasks: [BoardTask]) -> [BoardTask] {
        guard showStarredOnly else { return tasks }
        return tasks.filter(\.isPinned)
    }

    private var emptyState: some View {
        VStack(spacing: 9) {
            Image(systemName: "square.stack.3d.up.slash").font(.system(size: 32)).foregroundStyle(theme.secondaryText.opacity(0.6))
            Text("从一件事开始").font(.system(size: 14, weight: .semibold))
            Text("添加主体任务；同一项目的 AI 会话会自动归到一起。")
                .font(.system(size: 11)).foregroundStyle(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 64)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Circle().fill(theme.stateTint(.working)).frame(width: 6, height: 6)
            Text("任务 \(model.active.count)")
            Text("·")
            Circle().fill(theme.stateTint(.waiting)).frame(width: 6, height: 6)
            Text("等待会话 \(model.tasks.filter { $0.isConversation && $0.state == .waiting && model.isVisible($0, now: now) }.count)")
            Spacer()
            Text("数据保存在本机")
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(theme.secondaryText)
        .padding(.horizontal, 17).padding(.vertical, 12)
    }
}

struct TaskCard: View {
    let task: BoardTask
    @ObservedObject var model: BoardModel
    let now: Date
    @Environment(\.boardTheme) private var theme
    @State private var editingTitle = false
    @State private var titleDraft = ""
    @FocusState private var titleIsFocused: Bool
    @State private var expanded = false
    @State private var binding = false
    @State private var bindingSearch = ""
    @State private var menuOpen = false

    private var displayState: TaskState { model.displayState(for: task) }
    private var stateColor: Color { theme.stateTint(displayState) }
    private var childSessions: [BoardTask] { model.visibleChildren(of: task.id, now: now) }
    private var displaySince: Date {
        childSessions.first?.lastActivityAt ?? task.lastActivityAt
    }
    private var elapsed: String {
        let minutes = max(0, Int(now.timeIntervalSince(displaySince) / 60))
        if minutes < 1 { return "刚刚" }
        if minutes < 60 { return "\(minutes) 分钟" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours) 小时 \(minutes % 60) 分钟" }
        return "\(hours / 24) 天"
    }
    private var compactElapsed: String {
        let minutes = max(0, Int(now.timeIntervalSince(displaySince) / 60))
        if minutes < 1 { return "刚刚" }
        if minutes < 60 { return "\(minutes)分" }
        if minutes < 1440 { return "\(minutes / 60)时" }
        return "\(minutes / 1440)天"
    }
    private var previewSession: BoardTask? { task.isConversation ? task : childSessions.first }
    private var sourceLabel: String {
        guard let previewSession else { return "" }
        return previewSession.sourceName
    }
    private var summary: String {
        "\(displayState.rawValue) · \(compactElapsed) · \(stateSessionCount)会话"
    }
    private var stateSessionCount: Int {
        model.summarySessionCount(for: task, now: now)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 5) {
                Button {
                    model.openConversation(for: task, now: now)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(theme.iconBackground.opacity(0.8))
                        Image(systemName: displayState.symbol)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(theme.primaryText)
                    }
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("打开对应会话")

                if editingTitle {
                    TextField("任务名称", text: $titleDraft,
                              onEditingChanged: { if !$0 { finishTitleEdit() } },
                              onCommit: { finishTitleEdit() })
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.primaryText)
                        .focused($titleIsFocused)
                        .onExitCommand { cancelTitleEdit() }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(theme.mutedPanel, in: RoundedRectangle(cornerRadius: 5))
                } else {
                    Button {
                        beginTitleEdit()
                    } label: {
                        Text(task.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(displayState == .done ? theme.secondaryText.opacity(0.8) : theme.primaryText)
                            .strikethrough(displayState == .done)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("点击修改任务名称")
                }

                if !task.isConversation {
                    Text(task.isAutoGroup ? "自动" : "手动")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(theme.secondaryText)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(theme.secondaryText.opacity(0.10), in: RoundedRectangle(cornerRadius: 3))
                        .fixedSize()
                        .help(task.isAutoGroup ? "根据本地项目会话自动生成的分组" : "手动创建的主体任务")
                        .accessibilityLabel(task.isAutoGroup ? "自动分组" : "手动分组")
                }

                Button {
                    model.openConversation(for: task, now: now)
                } label: {
                        Text(summary)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(stateColor)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 5).padding(.vertical, 4)
                            .background(stateColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("打开对应会话")

                VStack(spacing: 2) {
                    Button { model.toggleTaskStar(task.id) } label: {
                        Image(systemName: task.isPinned ? "star.fill" : "star")
                            .foregroundStyle(task.isPinned ? theme.accent : theme.secondaryText)
                            .frame(width: 28, height: 25)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(task.isPinned ? "取消主体任务星标" : "星标主体任务")
                    if previewSession != nil {
                        Text(sourceLabel)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(theme.secondaryText.opacity(0.95))
                    }
                }
                .frame(width: 37)

                Button {
                        menuOpen.toggle()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(theme.secondaryText)
                            .frame(width: 28, height: 25)
                            .contentShape(Rectangle())
                    }
                    .help("任务操作")
                    .buttonStyle(.plain)
                    .popover(isPresented: $menuOpen, arrowEdge: .bottom) {
                        taskMenu
                    }
                .font(.system(size: 11))
                .frame(width: 28)
            }
            .frame(maxWidth: .infinity)

            if binding { bindingPanel }
            if !childSessions.isEmpty {
                Rectangle().fill(theme.border).frame(height: 1)
                VStack(alignment: .leading, spacing: 3) {
                    SessionRow(task: childSessions[0], parentID: task.id, model: model, now: now,
                               showSource: false)
                    if childSessions.count > 1 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) { expanded.toggle() }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: expanded ? "chevron.down" : "chevron.right")
                                Text(expanded ? "收起会话" : "展开全部 · \(childSessions.count)")
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(theme.secondaryText)
                            .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if expanded {
                            ForEach(childSessions.dropFirst()) { child in
                                Divider().overlay(theme.border.opacity(0.6))
                                SessionRow(task: child, parentID: task.id, model: model, now: now,
                                           showSource: true)
                            }
                        }
                    }
                }
                .padding(7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.mutedPanel, in: RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(theme.border))
            }
        }
        .padding(9)
        .background {
            RoundedRectangle(cornerRadius: 13)
                .fill(theme.card)
                .onTapGesture { finishTitleEdit() }
        }
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(theme.border.opacity(0.55)))
        .shadow(color: theme.isLight ? Color(red: 0.32, green: 0.45, blue: 0.65).opacity(0.10) : theme.accent.opacity(0.13), radius: 10, y: 3)
    }

    private func beginTitleEdit() {
        titleDraft = task.title
        editingTitle = true
        DispatchQueue.main.async { titleIsFocused = true }
    }

    private func finishTitleEdit() {
        guard editingTitle else { return }
        editingTitle = false
        titleIsFocused = false
        model.renameTask(task.id, to: titleDraft)
    }

    private func cancelTitleEdit() {
        editingTitle = false
        titleIsFocused = false
    }

    private var taskMenu: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(TaskState.allCases) { state in
                Button("标记为\(state.rawValue)") { model.setState(task.id, to: state); menuOpen = false }
            }
            Divider()
            if !task.isConversation {
                Button(binding ? "关闭绑定会话" : "绑定会话") {
                    binding.toggle()
                    if binding { model.loadCodexRecentForBinding() }
                    menuOpen = false
                }
            }
            if task.isConversation {
                ForEach(model.parentCandidates(for: task)) { parent in
                    Button("挂到：\(parent.title)") { model.assignParent(task.id, to: parent.id); menuOpen = false }
                }
            }
            Divider()
            Button("删除任务", role: .destructive) { model.remove(task.id); menuOpen = false }
        }
        .font(.system(size: 11))
        .padding(8)
        .frame(minWidth: 150, alignment: .leading)
        .background(theme.panel)
    }

    private var bindingPanel: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("绑定会话")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.primaryText)
                Spacer()
                Button("完成") { binding = false }
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(theme.accent)
            }
            TextField("搜索会话名称…", text: $bindingSearch)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .padding(7)
                .background(theme.card, in: RoundedRectangle(cornerRadius: 6))
            let candidates = model.bindableSessions(for: task.id).filter {
                bindingSearch.isEmpty || $0.title.localizedCaseInsensitiveContains(bindingSearch) ||
                    $0.sourceName.localizedCaseInsensitiveContains(bindingSearch) ||
                    ($0.projectKey?.localizedCaseInsensitiveContains(bindingSearch) ?? false)
            }
            if model.isLoadingCodexRecent {
                Text("正在读取 Codex 最近会话…")
                    .font(.system(size: 10))
                    .foregroundStyle(theme.secondaryText)
            }
            if candidates.isEmpty {
                if !model.isLoadingCodexRecent {
                    Text(bindingSearch.isEmpty ? "没有可绑定的会话" : "没有匹配的会话")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.secondaryText)
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(candidates) { candidate in
                            let isRecentCodex = candidate.codexThreadID != nil &&
                                !model.tasks.contains { $0.codexThreadID == candidate.codexThreadID }
                            let projectName = candidate.projectKey.map { URL(fileURLWithPath: $0).lastPathComponent } ?? ""
                            Button {
                                model.bindSession(candidate.id, to: task.id)
                            } label: {
                                HStack(spacing: 7) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(candidate.title)
                                            .lineLimit(1)
                                        Text(isRecentCodex ? "Codex 最近 · \(projectName)" :
                                             "\(candidate.sourceName) · \(candidate.isPinned ? "已保留" : candidate.state.rawValue)")
                                            .font(.system(size: 9))
                                            .foregroundStyle(theme.secondaryText)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(theme.accent)
                                }
                                .frame(minHeight: 34)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(theme.primaryText.opacity(0.9))
                        }
                    }
                }
                .frame(height: min(CGFloat(candidates.count) * 38, 220))
            }
        }
        .padding(9)
        .background(theme.mutedPanel, in: RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(theme.border))
    }

}

struct SessionRow: View {
    let task: BoardTask
    let parentID: UUID?
    @ObservedObject var model: BoardModel
    let now: Date
    let showSource: Bool
    @Environment(\.boardTheme) private var theme
    @State private var menuOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .top, spacing: 7) {
                Button {
                    model.openConversation(for: task, now: now)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.lastUserPreview.isEmpty ? userInputPreview(task.title) : task.lastUserPreview)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(task.state == .done ? theme.secondaryText.opacity(0.8) : theme.primaryText.opacity(0.92))
                            .lineLimit(1)
                            .help(task.lastUserPreview.isEmpty ? task.title : task.lastUserPreview)
                        HStack(spacing: 5) {
                            if showSource {
                                Text(task.sourceName)
                                Text("·")
                            }
                            Text(task.state.rawValue)
                            Text("·")
                            Text(relativeTime)
                            Spacer(minLength: 6)
                            Text(task.title)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(theme.secondaryText)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: 115, alignment: .trailing)
                                .help("会话名称：\(task.title)")
                        }
                        .font(.system(size: 10))
                        .foregroundStyle(task.state == .done ? theme.secondaryText : theme.stateTint(task.state))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("打开对应会话")
                Spacer(minLength: 3)
                Button {
                    menuOpen.toggle()
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(theme.secondaryText)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .popover(isPresented: $menuOpen, arrowEdge: .bottom) {
                    sessionMenu
                }
            }
        }
        .padding(.vertical, 3)
    }

    private var relativeTime: String {
        let minutes = max(0, Int(now.timeIntervalSince(task.stateSince) / 60))
        if minutes < 1 { return "刚刚" }
        if minutes < 60 { return "\(minutes) 分钟" }
        if minutes < 1440 { return "\(minutes / 60) 小时" }
        return "\(minutes / 1440) 天"
    }

    private var sessionMenu: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(TaskState.allCases) { state in
                Button(state.rawValue) { model.setState(task.id, to: state); menuOpen = false }
            }
            Divider()
            ForEach(model.parentCandidates(for: task)) { parent in
                Button("移到：\(parent.title)") { model.assignParent(task.id, to: parent.id); menuOpen = false }
            }
            if let parentID {
                Button("移出主体任务") { model.unbindSession(task.id, from: parentID); menuOpen = false }
            }
            Divider()
            Button("删除会话", role: .destructive) { model.remove(task.id); menuOpen = false }
        }
        .font(.system(size: 11))
        .padding(8)
        .frame(minWidth: 150, alignment: .leading)
        .background(theme.panel)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var edgeTimer: Timer?
    private var edgeHandle: NSPanel!
    private var topDocked = false
    private var edgeCollapsed = false
    private var explicitlyHidden = false
    private var pointerLeftAt: Date?
    private var menuIsTracking = false

    private func setupTopEdge() {
        panel.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(menuTrackingBegan),
                                               name: NSMenu.didBeginTrackingNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(menuTrackingEnded),
                                               name: NSMenu.didEndTrackingNotification, object: nil)
        edgeHandle = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        edgeHandle.level = .floating
        edgeHandle.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        edgeHandle.isOpaque = false
        edgeHandle.backgroundColor = .clear
        edgeHandle.hasShadow = false
        edgeHandle.isReleasedWhenClosed = false
        let grip = NSView()
        grip.wantsLayer = true
        grip.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.85).cgColor
        grip.layer?.cornerRadius = 3
        edgeHandle.contentView = grip
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTopEdge()
        }
        RunLoop.main.add(timer, forMode: .common)
        edgeTimer = timer
    }

    @objc private func menuTrackingBegan() { menuIsTracking = true }
    @objc private func menuTrackingEnded() {
        menuIsTracking = false
        pointerLeftAt = nil
    }

    private func updateTopEdge() {
        guard !explicitlyHidden, !menuIsTracking else { return }
        guard let screen = NSScreen.screens.max(by: {
            let a = $0.visibleFrame.intersection(panel.frame)
            let b = $1.visibleFrame.intersection(panel.frame)
            return max(0, a.width) * max(0, a.height) < max(0, b.width) * max(0, b.height)
        }) else { return }
        let bounds = screen.visibleFrame
        // Wait for the drag/resize to finish before changing window visibility.
        guard NSEvent.pressedMouseButtons == 0, !panel.inLiveResize else {
            pointerLeftAt = nil
            return
        }
        if !edgeCollapsed {
            guard panel.isVisible else { return }
            if abs(panel.frame.maxY - bounds.maxY) <= 12 {
                topDocked = true
            } else if abs(panel.frame.maxY - bounds.maxY) > 24 {
                topDocked = false
            }
        }
        guard topDocked else { pointerLeftAt = nil; return }
        let mouse = NSEvent.mouseLocation
        let handleWidth = min(100, bounds.width)
        let handleX = min(max(panel.frame.midX - handleWidth / 2, bounds.minX), bounds.maxX - handleWidth)
        let handleFrame = NSRect(x: handleX, y: bounds.maxY - 6, width: handleWidth, height: 6)
        edgeHandle.setFrame(handleFrame, display: false)
        if edgeCollapsed {
            // The small visible grip remains reachable below the menu bar.
            edgeHandle.orderFrontRegardless()
            if handleFrame.insetBy(dx: -8, dy: -3).contains(mouse) {
                var frame = panel.frame
                frame.origin.x = min(max(frame.minX, bounds.minX), bounds.maxX - frame.width)
                frame.origin.y = bounds.maxY - frame.height
                panel.setFrame(frame, display: true)
                edgeHandle.orderOut(nil)
                edgeCollapsed = false
                pointerLeftAt = nil
                panel.orderFrontRegardless()
            }
        } else if panel.frame.insetBy(dx: -8, dy: -8).contains(mouse)
                    || panel.attachedSheet != nil || NSApp.modalWindow != nil {
            pointerLeftAt = nil
        } else if let leftAt = pointerLeftAt {
            if Date().timeIntervalSince(leftAt) >= 0.65 {
                edgeCollapsed = true
                panel.orderOut(nil)
                edgeHandle.orderFrontRegardless()
                pointerLeftAt = nil
            }
        } else {
            pointerLeftAt = Date()
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hideBoard()
        return false
    }

    func applicationDidChangeScreenParameters(_ notification: Notification) {
        // Recover a reachable full window after monitors or their layout change.
        edgeHandle.orderOut(nil)
        edgeCollapsed = false
        topDocked = false
        pointerLeftAt = nil
        guard let bounds = (panel.screen ?? NSScreen.main)?.visibleFrame else { return }
        var frame = panel.frame
        frame.size.width = min(frame.width, bounds.width)
        frame.size.height = min(frame.height, bounds.height)
        frame.origin.x = min(max(frame.minX, bounds.minX), bounds.maxX - frame.width)
        frame.origin.y = min(max(frame.minY, bounds.minY), bounds.maxY - frame.height)
        panel.setFrame(frame, display: true)
        if !explicitlyHidden { panel.orderFrontRegardless() }
    }

    private let model = BoardModel()
    private var panel: NSPanel!
    private var statusItem: NSStatusItem!
    private var pollTimer: Timer?
    private var codexPollInFlight = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let screen = NSScreen.screens.first?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let initialHeight = min(700, max(430, screen.height - 90))
        panel = NSPanel(
            contentRect: NSRect(x: screen.maxX - 418, y: screen.maxY - initialHeight - 50,
                                width: 380, height: initialHeight),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Orbit"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.minSize = NSSize(width: 350, height: 430)
        let frameName = "DeskFocusBoardPanel"
        panel.setFrameAutosaveName(frameName)
        panel.setFrameUsingName(frameName)
        let savedFrame = panel.frame
        let visibleFrame = NSScreen.screens.first { $0.visibleFrame.intersects(savedFrame) }?.visibleFrame ?? screen
        let width = min(savedFrame.width, visibleFrame.width)
        let height = min(savedFrame.height, visibleFrame.height)
        let x = min(max(savedFrame.minX, visibleFrame.minX), visibleFrame.maxX - width)
        let y = min(max(savedFrame.minY, visibleFrame.minY), visibleFrame.maxY - height)
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: false)
        let lightSkin = UserDefaults.standard.string(forKey: "deskfocus.skin") == BoardSkin.apple.rawValue
        panel.appearance = NSAppearance(named: lightSkin ? .aqua : .darkAqua)
        panel.backgroundColor = lightSkin
            ? NSColor(red: 0.965, green: 0.978, blue: 1, alpha: 1)
            : NSColor(red: 0.075, green: 0.087, blue: 0.115, alpha: 1)
        panel.contentView = NSHostingView(rootView: BoardView(model: model))
        panel.isReleasedWhenClosed = false
        panel.makeKeyAndOrderFront(nil)
        setupTopEdge()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "circle.dotted", accessibilityDescription: "Orbit")
        statusItem.button?.image?.isTemplate = true
        statusItem.button?.toolTip = "Orbit"
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "显示 Orbit", action: #selector(showBoard), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "隐藏 Orbit", action: #selector(hideBoard), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        for item in menu.items { item.target = self }
        statusItem.menu = menu
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.model.pollCursor()
            self?.model.pollQoder()
            self?.model.pollQoderTranscripts()
            self?.pollCodex()
        }
        model.pollQoder()
        model.pollQoderTranscripts()
        model.pollCursor()
        pollCodex()
    }

    private func pollCodex() {
        guard !codexPollInFlight else { return }
        codexPollInFlight = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let sessions = CodexReader.sessions()
            DispatchQueue.main.async { [weak self] in
                self?.model.mergeCodex(sessions)
                self?.codexPollInFlight = false
            }
        }
    }

    @objc private func showBoard() {
        explicitlyHidden = false
        edgeCollapsed = false
        edgeHandle.orderOut(nil)
        pointerLeftAt = Date().addingTimeInterval(1)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    @objc private func hideBoard() {
        explicitlyHidden = true
        edgeCollapsed = false
        edgeHandle.orderOut(nil)
        panel.orderOut(nil)
    }
    @objc private func quit() { NSApp.terminate(nil) }
}

if CommandLine.arguments.contains("--cursor-scan") {
    print("Cursor sessions: \(CursorReader.sessions().count)")
} else if CommandLine.arguments.contains("--qoder-scan") {
    print("Qoder sessions: \(QoderReader.sessions().map { "\($0.id) \($0.state.rawValue)" })")
} else if CommandLine.arguments.contains("--codex-scan") {
    let sessions = CodexReader.sessions()
    print("Codex sessions: \(sessions.count), waiting: \(sessions.filter { $0.state == .waiting }.count), ready: \(sessions.filter { $0.state == .ready }.count)")
} else if CommandLine.arguments.contains("--codex-recent-self-test") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("deskfocus-recent-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let databaseURL = directory.appendingPathComponent("recent.sqlite")
    let rolloutURL = directory.appendingPathComponent("old-rollout.jsonl")
    let threadID = UUID().uuidString
    let oldTime = Int(Date().addingTimeInterval(-9 * 86400).timeIntervalSince1970)
    let oldUser = "{\"type\":\"response_item\",\"payload\":{\"type\":\"message\",\"role\":\"user\",\"content\":[{\"type\":\"input_text\",\"text\":\"请继续\"}]}}\n"
    let oldReply = "{\"type\":\"response_item\",\"payload\":{\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"output_text\",\"text\":\"请确认项目目录。\"}]}}\n"
    let oldCompletion = "{\"type\":\"event_msg\",\"payload\":{\"type\":\"task_complete\"}}\n"
    try (oldUser + oldReply + oldCompletion).write(to: rolloutURL, atomically: true, encoding: .utf8)
    var database: OpaquePointer?
    precondition(sqlite3_open(databaseURL.path, &database) == SQLITE_OK)
    precondition(sqlite3_exec(database, "CREATE TABLE threads (id TEXT, name TEXT, title TEXT, cwd TEXT, rollout_path TEXT, updated_at INTEGER, recency_at INTEGER, archived INTEGER)", nil, nil, nil) == SQLITE_OK)
    let insert = "INSERT INTO threads VALUES ('\(threadID)', '旧任务', '旧任务', '/tmp/project', '\(rolloutURL.path)', \(oldTime), \(oldTime), 0)"
    precondition(sqlite3_exec(database, insert, nil, nil, nil) == SQLITE_OK)
    sqlite3_close(database)
    precondition(CodexReader.sessions(databaseURL: databaseURL).isEmpty)
    let recent = CodexReader.recentThreads(databaseURL: databaseURL)
    precondition(recent.count == 1 && recent[0].id == threadID)
    precondition(CodexReader.recentActivity(at: recent[0].rolloutPath)?.0 == .human)
    let model = BoardModel(dataDirectory: directory)
    model.add("自定义任务一")
    model.add("自定义任务二")
    let first = model.tasks.first { $0.title == "自定义任务一" }!
    let second = model.tasks.first { $0.title == "自定义任务二" }!
    model.setCodexRecentForBinding(recent)
    let candidate = model.bindableSessions(for: first.id).first!
    precondition(candidate.codexThreadID == threadID)
    model.bindSession(candidate.id, to: first.id)
    let bound = model.tasks.first { $0.codexThreadID == threadID }!
    precondition(bound.isPinned && model.visibleChildren(of: first.id).contains { $0.id == bound.id })
    let deadline = Date().addingTimeInterval(2)
    while model.tasks.first(where: { $0.id == bound.id })?.state != .human && Date() < deadline {
        RunLoop.main.run(until: Date().addingTimeInterval(0.02))
    }
    precondition(model.tasks.first(where: { $0.id == bound.id })?.state == .human)
    model.bindSession(bound.id, to: second.id)
    let restored = BoardModel(dataDirectory: directory)
    precondition(restored.visibleChildren(of: first.id).contains { $0.codexThreadID == threadID })
    precondition(restored.visibleChildren(of: second.id).contains { $0.codexThreadID == threadID })
    print("Codex recent self-test passed")
} else if CommandLine.arguments.contains("--auto-group-repair-self-test") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("orbit-group-repair-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let key = directory.appendingPathComponent("project").path
    let otherKey = directory.appendingPathComponent("other-project").path
    var old = BoardTask(title: "旧自动名称")
    old.projectKey = key; old.isAutoGroup = true; old.state = .done; old.isPinned = true
    var current = BoardTask(title: "project")
    current.projectKey = key; current.isAutoGroup = true
    var manual = BoardTask(title: "手动分组")
    manual.projectKey = key
    var first = BoardTask(title: "已恢复的旧会话")
    first.qoderSessionID = "repair-first"; first.projectKey = key; first.parentID = old.id
    first.boundParentIDs = [manual.id]
    var second = BoardTask(title: "新会话")
    second.qoderSessionID = "repair-second"; second.projectKey = key; second.parentID = current.id
    var misplaced = BoardTask(title: "另一个项目的会话")
    misplaced.qoderSessionID = "repair-other"; misplaced.projectKey = otherKey; misplaced.parentID = old.id
    var owned = BoardTask(title: "手动归属")
    owned.qoderSessionID = "repair-manual"; owned.projectKey = key; owned.parentID = manual.id
    owned.boundParentIDs = [old.id]
    let original = [old,current,manual,first,second,misplaced,owned]
    let repaired = BoardModel.normalizedAutoGroups(original)
    precondition(repaired.filter { $0.isAutoGroup && $0.projectKey == key }.count == 1)
    precondition(repaired.first { $0.id == first.id }!.parentID == current.id)
    precondition(repaired.first { $0.id == second.id }!.parentID == current.id)
    precondition(repaired.first { $0.id == first.id }!.boundParentIDs == [manual.id])
    precondition(repaired.first { $0.id == owned.id }!.parentID == manual.id)
    precondition(repaired.first { $0.id == owned.id }!.boundParentIDs == [current.id])
    precondition(repaired.first { $0.id == current.id }!.isPinned)
    let moved = repaired.first { $0.id == misplaced.id }!
    precondition(repaired.first { $0.id == moved.parentID }!.projectKey == otherKey)
    precondition(repaired.first { $0.id == manual.id }!.title == "手动分组")
    let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
    let twice = BoardModel.normalizedAutoGroups(repaired)
    let encodedOnce = try encoder.encode(repaired)
    let encodedTwice = try encoder.encode(twice)
    precondition(encodedOnce == encodedTwice)
    let file = directory.appendingPathComponent("tasks.json")
    try encoder.encode(original).write(to: file)
    let model = BoardModel(dataDirectory: directory)
    precondition(FileManager.default.fileExists(atPath: directory.appendingPathComponent("tasks-before-auto-group-repair.json").path))
    precondition(model.tasks.filter { $0.isAutoGroup && $0.projectKey == key }.count == 1)
    model.setState(current.id, to: .done)
    let session = CursorSession(path: directory.appendingPathComponent("new.jsonl").path, title: "再次进入项目", lastUserPreview: "测试",
                                modified: Date(), lineCount: 0, projectKey: key, projectTitle: "project")
    model.importCursor(session)
    precondition(model.tasks.filter { $0.isAutoGroup && $0.projectKey == key }.count == 1)
    precondition(model.tasks.first { $0.cursorPath == session.path }!.parentID == current.id)
    let restored = BoardModel(dataDirectory: directory)
    precondition(restored.tasks.filter { $0.isAutoGroup && $0.projectKey == key }.count == 1)
    print("Automatic group repair self-test passed")
} else if CommandLine.arguments.contains("--qoder-resume-self-test") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("orbit-qoder-resume-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let root = directory.appendingPathComponent("projects")
    let project = root.appendingPathComponent("example")
    try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
    let transcript = project.appendingPathComponent("session.jsonl")
    func userRecord(_ prompt: String, at date: Date) throws -> String {
        let object: [String: Any] = ["type": "user", "sessionId": "resume-test", "cwd": "/tmp/example",
                                    "timestamp": ISO8601DateFormatter().string(from: date),
                                    "message": ["content": [["type": "text", "text": prompt]]]]
        return String(data: try JSONSerialization.data(withJSONObject: object), encoding: .utf8)! + "\n"
    }
    let old = try userRecord("旧问题", at: Date().addingTimeInterval(-120))
    try old.write(to: transcript, atomically: true, encoding: .utf8)
    let model = BoardModel(dataDirectory: directory)
    model.pollQoderTranscripts(root: root)
    let id = model.tasks.first { $0.qoderSessionID == "resume-test" }!.id
    model.setState(id, to: .done)
    model.update(id) { $0.stateSince = Date().addingTimeInterval(-60) }
    // Unrelated transcript growth must preserve a manual completion.
    try (old + "{\"type\":\"active-leaf\"}\n").write(to: transcript, atomically: true, encoding: .utf8)
    model.pollQoderTranscripts(root: root)
    precondition(model.tasks.first { $0.id == id }!.state == .done)
    let new = try userRecord("新问题", at: Date().addingTimeInterval(-1))
    try (old + new).write(to: transcript, atomically: true, encoding: .utf8)
    // Same record count still needs to recover the previously stuck completed task.
    model.pollQoderTranscripts(root: root)
    precondition(model.tasks.first { $0.id == id }!.state == .waiting)
    precondition(model.tasks.first { $0.id == id }!.lastUserPreview == "新问题")
    model.setState(id, to: .done)
    model.pollQoderTranscripts(root: root)
    precondition(model.tasks.first { $0.id == id }!.state == .done)
    let interrupted = try userRecord("[Request interrupted by user]", at: Date())
    try (old + new + interrupted).write(to: transcript, atomically: true, encoding: .utf8)
    let stoppedSession = QoderReader.sessions(root: root).first!
    precondition(stoppedSession.wasInterrupted && stoppedSession.state == .ready)
    precondition(stoppedSession.lastUserPreview == "新问题")
    model.update(id) {
        $0.state = .waiting
        $0.qoderObservedLines = stoppedSession.lineCount
        $0.lastActivityAt = stoppedSession.modified
    }
    model.pollQoderTranscripts(root: root)
    precondition(model.tasks.first { $0.id == id }!.state == .ready)
    model.setState(id, to: .done)
    model.pollQoderTranscripts(root: root)
    precondition(model.tasks.first { $0.id == id }!.state == .done)
    let resumed = try userRecord("停止后继续", at: Date())
    try (old + new + interrupted + resumed).write(to: transcript, atomically: true, encoding: .utf8)
    let resumedSession = QoderReader.sessions(root: root).first!
    precondition(!resumedSession.wasInterrupted && resumedSession.state == .waiting)
    precondition(resumedSession.lastUserPreview == "停止后继续")
    let suite = "orbit-qoder-test-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    model.update(id) { $0.stateSince = Date().addingTimeInterval(-60) }
    let event: [String: String] = ["session_id": "resume-test", "hook_event_name": "UserPromptSubmit",
                                   "cwd": "/tmp/example", "prompt_preview": "Hook 新问题",
                                   "timestamp": ISO8601DateFormatter().string(from: Date())]
    var data = try JSONSerialization.data(withJSONObject: event)
    data.append(0x0a)
    try data.write(to: directory.appendingPathComponent("qoder-events.jsonl"))
    defaults.set(500, forKey: "qoderEventLineCount")
    model.pollQoder(defaults: defaults)
    precondition(model.tasks.first { $0.id == id }!.state == .waiting)
    precondition(model.tasks.first { $0.id == id }!.lastUserPreview == "Hook 新问题")
    precondition(defaults.integer(forKey: "qoderEventLineCount") == 1)
    print("Qoder resume self-test passed")
} else if CommandLine.arguments.contains("--human-state-self-test") {
    precondition(HumanActionDetector.needsHuman("需要你确认项目目录后我才能继续。"))
    precondition(HumanActionDetector.needsHuman("Please run the command and share its output."))
    precondition(!HumanActionDetector.needsHuman("已完成修改，构建和测试均通过。"))
    let user: [String: Any] = ["role": "user", "message": ["content": [["type": "text", "text": "请修改代码"]]]]
    let assistant: [String: Any] = ["role": "assistant", "message": ["content": [["type": "text", "text": "请确认使用哪个目录。"]]]]
    let end: [String: Any] = ["type": "turn_ended"]
    precondition(CursorReader.inferredState(in: [user]) == .waiting)
    precondition(CursorReader.inferredState(in: [user, assistant, end]) == .human)
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("deskfocus-human-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    let qoderRoot = directory.appendingPathComponent("qoder-projects")
    let qoderProject = qoderRoot.appendingPathComponent("example")
    try FileManager.default.createDirectory(at: qoderProject, withIntermediateDirectories: true)
    let qoderUser = "{\"sessionId\":\"human-test\",\"cwd\":\"/tmp/project\",\"type\":\"user\",\"message\":{\"content\":[{\"type\":\"text\",\"text\":\"请修改代码\"}]}}\n"
    let qoderAssistant = "{\"sessionId\":\"human-test\",\"type\":\"assistant\",\"message\":{\"stop_reason\":\"end_turn\",\"content\":[{\"type\":\"text\",\"text\":\"请手动运行迁移命令。\"}]}}\n"
    try (qoderUser + qoderAssistant).write(to: qoderProject.appendingPathComponent("human.jsonl"),
                                      atomically: true, encoding: .utf8)
    precondition(QoderReader.sessions(root: qoderRoot).first?.state == .human)
    let model = BoardModel(dataDirectory: directory)
    let session = CursorSession(path: directory.appendingPathComponent("human.jsonl").path,
                                title: "澄清需求", lastUserPreview: "请修改代码", modified: Date(),
                                lineCount: 3, projectKey: directory.path, projectTitle: "测试项目", state: .human)
    model.importCursor(session)
    let parent = model.active[0]
    let child = model.children(of: parent.id)[0]
    precondition(model.displayState(for: parent) == .human)
    precondition(model.summarySessionCount(for: parent) == 1)
    model.setState(child.id, to: .ready)
    precondition(model.displayState(for: parent) == .ready)
    let restored = BoardModel(dataDirectory: directory)
    precondition(restored.tasks.first { $0.id == child.id }?.state == .ready)
    print("Human-state self-test passed")
} else if CommandLine.arguments.contains("--codex-self-test") {
    precondition(userInputPreview(String(repeating: "字", count: 31)) == String(repeating: "字", count: 30) + "…")
    precondition(userInputPreview("第一行\n 第二行") == "第一行 第二行")
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("deskfocus-codex-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let databaseURL = directory.appendingPathComponent("state_5.sqlite")
    let rolloutURL = directory.appendingPathComponent("thread.jsonl")
    let firstInput = "{\"type\":\"response_item\",\"payload\":{\"type\":\"message\",\"role\":\"user\",\"content\":[{\"type\":\"input_text\",\"text\":\"第一次输入\"}]}}\n"
    let started = firstInput + "{\"type\":\"event_msg\",\"payload\":{\"type\":\"task_started\"}}\n"
    try started.write(to: rolloutURL, atomically: true, encoding: .utf8)
    var database: OpaquePointer?
    precondition(sqlite3_open(databaseURL.path, &database) == SQLITE_OK)
    let createSQL = "CREATE TABLE threads (id TEXT, name TEXT, title TEXT, cwd TEXT, rollout_path TEXT, updated_at INTEGER, archived INTEGER)"
    precondition(sqlite3_exec(database, createSQL, nil, nil, nil) == SQLITE_OK)
    var insert: OpaquePointer?
    precondition(sqlite3_prepare_v2(database, "INSERT INTO threads VALUES (?, ?, ?, ?, ?, ?, 0)", -1, &insert, nil) == SQLITE_OK)
    let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    sqlite3_bind_text(insert, 1, "test-thread", -1, transient)
    sqlite3_bind_text(insert, 2, "测试 Codex 会话", -1, transient)
    sqlite3_bind_text(insert, 3, "原始标题", -1, transient)
    sqlite3_bind_text(insert, 4, directory.path, -1, transient)
    sqlite3_bind_text(insert, 5, rolloutURL.path, -1, transient)
    sqlite3_bind_int64(insert, 6, Int64(Date().timeIntervalSince1970))
    precondition(sqlite3_step(insert) == SQLITE_DONE)
    sqlite3_finalize(insert)
    sqlite3_close(database)
    let waiting = CodexReader.sessions(databaseURL: databaseURL, now: Date().addingTimeInterval(-10))
    precondition(waiting.count == 1 && waiting[0].state == .waiting && waiting[0].title == "测试 Codex 会话")
    precondition(waiting[0].lastUserPreview == "第一次输入")
    let model = BoardModel(dataDirectory: directory)
    model.mergeCodex(waiting)
    precondition(model.children(of: model.active[0].id).first?.state == .waiting)
    let secondInput = "{\"type\":\"response_item\",\"payload\":{\"type\":\"message\",\"role\":\"user\",\"content\":[{\"type\":\"input_text\",\"text\":\"第二次输入\"}]}}\n"
    let completed = started + secondInput + "{\"type\":\"event_msg\",\"payload\":{\"type\":\"task_complete\"}}\n"
    try completed.write(to: rolloutURL, atomically: true, encoding: .utf8)
    let ready = CodexReader.sessions(databaseURL: databaseURL)
    precondition(ready.count == 1 && ready[0].state == .ready && ready[0].lastUserPreview == "第二次输入")
    model.mergeCodex(ready)
    precondition(model.active.count == 1)
    precondition(model.children(of: model.active[0].id).count == 1)
    precondition(model.children(of: model.active[0].id).first?.state == .ready)
    precondition(model.children(of: model.active[0].id).first?.lastUserPreview == "第二次输入")
    precondition(model.navigationTarget(for: model.active[0])?.codexThreadID == "test-thread")
    let restored = BoardModel(dataDirectory: directory)
    precondition(restored.tasks.contains { $0.codexThreadID == "test-thread" && $0.lastUserPreview == "第二次输入" })
    let humanReply = "{\"type\":\"response_item\",\"payload\":{\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"output_text\",\"text\":\"请确认你希望使用哪个目录。\"}]}}\n"
    let needsHuman = started + secondInput + humanReply + "{\"type\":\"event_msg\",\"payload\":{\"type\":\"task_complete\"}}\n"
    try needsHuman.write(to: rolloutURL, atomically: true, encoding: .utf8)
    precondition(CodexReader.sessions(databaseURL: databaseURL)[0].state == .human)
    print("Codex self-test passed")
} else if CommandLine.arguments.contains("--grouping-self-test") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("deskfocus-grouping-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    let model = BoardModel(dataDirectory: directory)
    let first = CursorSession(path: "/tmp/one.jsonl", title: "会话一", lastUserPreview: "会话一", modified: Date(), lineCount: 1,
                              projectKey: "/tmp/project", projectTitle: "project")
    let second = CursorSession(path: "/tmp/two.jsonl", title: "会话二", lastUserPreview: "会话二", modified: Date(), lineCount: 1,
                               projectKey: "/tmp/project", projectTitle: "project")
    model.importCursor(first)
    model.importCursor(second)
    precondition(model.active.count == 1)
    let autoParentID = model.active[0].id
    precondition(model.children(of: autoParentID).count == 2)
    model.add("自定义组合")
    let customParent = model.tasks.first { $0.title == "自定义组合" }!
    model.renameTask(customParent.id, to: "  自定义组合（已改名）  ")
    precondition(model.tasks.first { $0.id == customParent.id }?.title == "自定义组合（已改名）")
    model.add("第二个组合")
    let secondParent = model.tasks.first { $0.title == "第二个组合" }!
    let firstID = model.tasks.first { $0.cursorPath == first.path }!.id
    model.bindSession(firstID, to: customParent.id)
    model.bindSession(firstID, to: secondParent.id)
    precondition(model.tasks.first { $0.id == firstID }?.belongs(to: customParent.id) == true)
    precondition(model.tasks.first { $0.id == firstID }?.belongs(to: secondParent.id) == true)
    let restoredBound = BoardModel(dataDirectory: directory)
    precondition(restoredBound.tasks.first { $0.id == firstID }?.belongs(to: customParent.id) == true)
    precondition(restoredBound.tasks.first { $0.id == firstID }?.belongs(to: secondParent.id) == true)
    model.unbindSession(firstID, from: customParent.id)
    precondition(model.tasks.first { $0.id == firstID }?.belongs(to: customParent.id) == false)
    precondition(model.tasks.first { $0.id == firstID }?.belongs(to: secondParent.id) == true)
    model.assignParent(firstID, to: nil)
    precondition(model.tasks.first { $0.id == firstID }?.parentID == nil)
    precondition(model.tasks.first { $0.id == firstID }?.boundParentIDs.isEmpty == true)
    model.bindSession(firstID, to: autoParentID)
    model.remove(customParent.id)
    model.remove(secondParent.id)
    let restored = BoardModel(dataDirectory: directory)
    precondition(restored.active.count == 1)
    precondition(restored.children(of: restored.active[0].id).count == 2)
    print("Grouping self-test passed")
} else if CommandLine.arguments.contains("--lifecycle-self-test") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("deskfocus-lifecycle-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    let model = BoardModel(dataDirectory: directory)
    let now = Date()
    let old = CursorSession(path: directory.appendingPathComponent("old.jsonl").path, title: "旧会话", lastUserPreview: "旧会话",
                            modified: now.addingTimeInterval(-2 * 86400), lineCount: 1,
                            projectKey: directory.path, projectTitle: directory.lastPathComponent)
    let recent = CursorSession(path: directory.appendingPathComponent("recent.jsonl").path, title: "新会话", lastUserPreview: "新会话",
                               modified: now.addingTimeInterval(-3600), lineCount: 1,
                               projectKey: directory.path, projectTitle: directory.lastPathComponent)
    model.importCursor(old)
    model.importCursor(recent)
    let parent = model.tasks.first { $0.parentID == nil && $0.isAutoGroup }!
    let oldID = model.tasks.first { $0.cursorPath == old.path }!.id
    let recentID = model.tasks.first { $0.cursorPath == recent.path }!.id
    precondition(model.visibleChildren(of: parent.id, now: now).map(\.id) == [recentID])
    precondition(model.navigationTarget(for: parent, now: now)?.id == recentID)
    precondition(model.summarySessionCount(for: parent, now: now) == 1)
    model.setState(recentID, to: .working)
    precondition(model.summarySessionCount(for: parent, now: now) == 1)
    model.update(recentID) { $0.link = "https://example.com/session/123" }
    precondition(model.directURL(for: model.tasks.first { $0.id == recentID }!)?.absoluteString == "https://example.com/session/123")
    model.update(recentID) { $0.link = "file:///tmp/other-session" }
    precondition(model.directURL(for: model.tasks.first { $0.id == recentID }!) == nil)
    model.setState(recentID, to: .done)
    precondition(model.visibleChildren(of: parent.id, now: now).count == 1)
    precondition(model.visibleChildren(of: parent.id, now: now.addingTimeInterval(23 * 3600)).isEmpty)
    model.setPinned(oldID)
    precondition(model.visibleChildren(of: parent.id, now: now).first?.id == recentID)
    precondition(model.navigationTarget(for: parent, now: now)?.id == recentID)
    precondition(model.isVisible(parent, now: now.addingTimeInterval(8 * 86400)))
    model.setPinned(oldID)
    precondition(!model.isVisible(parent, now: now.addingTimeInterval(8 * 86400)))
    model.update(oldID) { $0.lastActivityAt = now.addingTimeInterval(8 * 86400) }
    precondition(model.isVisible(parent, now: now.addingTimeInterval(8 * 86400)))

    let legacyURL = directory.appendingPathComponent("tasks.json")
    let legacy = try! JSONSerialization.jsonObject(with: Data(contentsOf: legacyURL)) as! [[String: Any]]
    let withoutNewKeys = legacy.map { item -> [String: Any] in
        var copy = item
        copy.removeValue(forKey: "lastActivityAt")
        copy.removeValue(forKey: "isPinned")
        copy.removeValue(forKey: "isAutoGroup")
        copy.removeValue(forKey: "lastUserPreview")
        return copy
    }
    try! JSONSerialization.data(withJSONObject: withoutNewKeys).write(to: legacyURL)
    let restored = BoardModel(dataDirectory: directory)
    precondition(restored.tasks.count == model.tasks.count)
    precondition(restored.tasks.contains { $0.id == parent.id && $0.isAutoGroup })

    let livePath = directory.appendingPathComponent("live.jsonl")
    try! "{\"role\":\"user\"}\n{\"type\":\"turn_ended\"}\n".write(to: livePath, atomically: true, encoding: .utf8)
    let live = CursorSession(path: livePath.path, title: "同步测试", lastUserPreview: "同步测试", modified: now.addingTimeInterval(-3600),
                             lineCount: 0, projectKey: directory.path, projectTitle: "测试项目")
    restored.importCursor(live)
    let liveID = restored.tasks.first { $0.cursorPath == livePath.path }!.id
    restored.update(liveID) { $0.lastActivityAt = now.addingTimeInterval(-3600) }
    restored.pollCursor()
    precondition(restored.tasks.first { $0.id == liveID }!.lastActivityAt > now.addingTimeInterval(-60))
    print("Lifecycle self-test passed")
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
