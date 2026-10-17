import AppKit
import Darwin
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

enum GroupingMode: String, Codable { case auto, manual, detached }

struct BoardTask: Identifiable, Codable, Equatable {
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
    var groupingMode: GroupingMode = .auto
    var isTitleCustomized = false
    var completionOverride = false

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
        case lastActivityAt, isPinned, isAutoGroup, groupingMode, isTitleCustomized, completionOverride
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
        groupingMode = try values.decodeIfPresent(GroupingMode.self, forKey: .groupingMode)
            ?? (parentID == nil && !boundParentIDs.isEmpty ? .manual : .auto)
        isTitleCustomized = try values.decodeIfPresent(Bool.self, forKey: .isTitleCustomized) ?? false
        completionOverride = try values.decodeIfPresent(Bool.self, forKey: .completionOverride)
            ?? (!isConversation && state == .done)
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
        SyntheticAccess.check(URL(fileURLWithPath: path))
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              String(data: data, encoding: .utf8) != nil else { return [] }
        return data.withUnsafeBytes { raw -> [[String: Any]] in
            guard let base = raw.baseAddress else { return [] }
            var result: [[String: Any]] = []
            var start = 0
            while start < raw.count {
                let delimiter = memchr(base.advanced(by: start), 10, raw.count - start)
                let end = delimiter.map { base.distance(to: $0) } ?? raw.count
                if end > start {
                    let row = Data(bytes: base.advanced(by: start), count: end - start)
                    if let object = (try? JSONSerialization.jsonObject(with: row)) as? [String: Any] { result.append(object) }
                }
                start = end + 1
            }
            return result
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

    static func sessions(root: URL = root) -> [CursorSession] {
        SyntheticAccess.check(root)
        guard let projects = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { return [] }
        var found: [CursorSession] = []
        for project in projects {
            let transcripts = project.appendingPathComponent("agent-transcripts", isDirectory: true)
            SyntheticAccess.check(transcripts)
            let projectName = project.lastPathComponent
            let decodedPath = "/" + projectName.replacingOccurrences(of: "-", with: "/")
            let projectKey = SyntheticAccess.exists(decodedPath)
                ? URL(fileURLWithPath: decodedPath).standardizedFileURL.path
                : project.standardizedFileURL.path
            let projectTitle = SyntheticAccess.exists(decodedPath)
                ? URL(fileURLWithPath: decodedPath).lastPathComponent
                : (projectName.split(separator: "-").last.map(String.init) ?? "Cursor 项目")
            guard let agents = try? FileManager.default.contentsOfDirectory(at: transcripts, includingPropertiesForKeys: nil) else { continue }
            for agent in agents {
                let file = agent.appendingPathComponent(agent.lastPathComponent + ".jsonl")
                SyntheticAccess.check(file)
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
        SyntheticAccess.check(root)
        guard let projects = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { return [] }
        var found: [QoderSession] = []
        for project in projects {
            SyntheticAccess.check(project)
            guard let files = try? FileManager.default.contentsOfDirectory(at: project, includingPropertiesForKeys: nil) else { continue }
            for file in files where file.pathExtension == "jsonl" {
                SyntheticAccess.check(file)
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

enum CodexReadDiagnostic: String {
    case recognizedState, irrelevant, incompleteTail, unknownStateSchema, readFailure
}

struct CodexSession {
    let id: String
    let title: String
    let lastUserPreview: String
    let state: TaskState
    let modified: Date
    let projectKey: String
    let projectTitle: String
    var stateIsTrusted = true
    var readDiagnostic: CodexReadDiagnostic = .recognizedState
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
        SyntheticAccess.check(databaseURL)
        databaseResult(databaseURL, .readFailure)
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
        var step = sqlite3_step(statement)
        while step == SQLITE_ROW {
            defer { step = sqlite3_step(statement) }
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
        guard step == SQLITE_DONE else { return [] }
        databaseResult(databaseURL, .irrelevant)
        return found
    }

    static func recentActivity(at path: String) -> (TaskState, String)? {
        SyntheticAccess.check(URL(fileURLWithPath: path))
        let activity = latestActivity(at: path)
        guard activity.stateIsTrusted else { return nil }
        return (activity.state, activity.lastUserPreview)
    }

    private struct Activity {
        let state: TaskState
        let lastUserPreview: String
        var diagnostic: CodexReadDiagnostic = .recognizedState
        var stateIsTrusted = true
        var scannedLines = 0
    }

    private struct CachedState {
        let size: Int
        let modified: Date
        let activity: Activity
    }
    private static var stateCache: [String: CachedState] = [:]
    private static let stateQueue = DispatchQueue(label: "local.orbit.codex-state-cache")
    private static var databaseDiagnostics: [String: CodexReadDiagnostic] = [:]

    static func diagnostic(at path: String) -> CodexReadDiagnostic { latestActivity(at: path).diagnostic }
    static func scannedLineCount(at path: String) -> Int { latestActivity(at: path).scannedLines }
    static func databaseDiagnostic(at url: URL) -> CodexReadDiagnostic? {
        stateQueue.sync { databaseDiagnostics[url.path] }
    }
    private static func databaseResult(_ url: URL, _ result: CodexReadDiagnostic) {
        stateQueue.sync { databaseDiagnostics[url.path] = result }
    }

    static func sessions(databaseURL: URL = databaseURL, now: Date = Date()) -> [CodexSession] {
        SyntheticAccess.check(databaseURL)
        databaseResult(databaseURL, .readFailure)
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
        var step = sqlite3_step(statement)
        while step == SQLITE_ROW {
            defer { step = sqlite3_step(statement) }
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
            SyntheticAccess.check(URL(fileURLWithPath: rolloutPath))
            let attrs = try? FileManager.default.attributesOfItem(atPath: rolloutPath)
            let fileModified = attrs?[.modificationDate] as? Date ?? .distantPast
            let modified = min(max(databaseModified, fileModified), now)
            let activity = latestActivity(at: rolloutPath)
            found.append(CodexSession(id: id, title: String(title.prefix(90)),
                                      lastUserPreview: activity.lastUserPreview,
                                      state: activity.state, modified: modified,
                                      projectKey: projectPath, projectTitle: projectTitle,
                                      stateIsTrusted: activity.stateIsTrusted, readDiagnostic: activity.diagnostic))
        }
        guard step == SQLITE_DONE else { return [] }
        databaseResult(databaseURL, .irrelevant)
        return found
    }

    private static func latestActivity(at path: String) -> Activity {
        stateQueue.sync { latestActivityLocked(at: path) }
    }

    private static func latestActivityLocked(at path: String) -> Activity {
        SyntheticAccess.check(URL(fileURLWithPath: path))
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attrs[.size] as? Int,
              let modified = attrs[.modificationDate] as? Date else {
            return Activity(state: stateCache[path]?.activity.state ?? .working,
                            lastUserPreview: stateCache[path]?.activity.lastUserPreview ?? "",
                            diagnostic: .readFailure, stateIsTrusted: false)
        }
        if let cached = stateCache[path], cached.size == size, cached.modified == modified {
            return cached.activity
        }
        var activity = scanLatestActivity(at: path, size: size)
        if !activity.stateIsTrusted, let trusted = stateCache[path]?.activity {
            activity = Activity(state: trusted.state,
                                lastUserPreview: activity.lastUserPreview.isEmpty ? trusted.lastUserPreview : activity.lastUserPreview,
                                diagnostic: activity.diagnostic, stateIsTrusted: false, scannedLines: activity.scannedLines)
        }
        // An incomplete tail must be re-read even if a writer preserves size and mtime.
        if activity.stateIsTrusted && activity.diagnostic != .incompleteTail {
            stateCache[path] = CachedState(size: size, modified: modified, activity: activity)
        }
        return activity
    }

    private static func scanLatestActivity(at path: String, size: Int) -> Activity {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) else {
            return Activity(state: .working, lastUserPreview: "", diagnostic: .readFailure, stateIsTrusted: false)
        }
        var end = data.endIndex
        var isTail = true
        var scannedLines = 0
        let newline = Data([10])
        var state: TaskState?
        var lastInput: String?
        var reply: String?
        var stateIndex: Int?
        var userIndex: Int?
        var replyIndex: Int?
        var diagnostic: CodexReadDiagnostic = .irrelevant
        var unknownStateIndex: Int?
        while end > data.startIndex {
            while end > data.startIndex && data[end - 1] == 10 { end -= 1 }
            guard end > data.startIndex else { break }
            let start = data.range(of: newline, options: .backwards, in: data.startIndex..<end)?.upperBound ?? data.startIndex
            let row = data[start..<end]
            end = start > data.startIndex ? start - 1 : data.startIndex
            let index = start // Byte offsets preserve chronology without scanning the entire file.
            scannedLines += 1
            guard let event = (try? JSONSerialization.jsonObject(with: Data(row))) as? [String: Any] else {
                if isTail { diagnostic = .incompleteTail }
                isTail = false
                continue
            }
            isTail = false
            if event["type"] as? String == "event_msg" {
                let payload = event["payload"] as? [String: Any]
                let kind = payload?["type"] as? String
                if let recognized = eventState(in: event), state == nil {
                    state = recognized; stateIndex = index
                } else if kind == nil || kind!.hasPrefix("task_") || kind!.hasPrefix("turn_") {
                    if eventState(in: event) == nil {
                        if unknownStateIndex == nil { unknownStateIndex = index }
                        if diagnostic != .incompleteTail { diagnostic = .unknownStateSchema }
                    }
                }
            }
            if lastInput == nil, let preview = userText(in: event) { lastInput = preview; userIndex = index }
            if reply == nil, let text = assistantText(in: event) { reply = text; replyIndex = index }
            if state != nil && lastInput != nil { break }
        }
        if state == .ready, let completion = stateIndex, let user = userIndex,
           let assistant = replyIndex, completion > assistant && assistant > user,
           let reply, HumanActionDetector.needsHuman(reply) { state = .human }
        if diagnostic == .unknownStateSchema, let recognized = stateIndex, let unknown = unknownStateIndex,
           recognized > unknown { diagnostic = .recognizedState }
        if diagnostic == .irrelevant && state != nil { diagnostic = .recognizedState }
        let trustworthy = state != nil && diagnostic != .incompleteTail && diagnostic != .unknownStateSchema
        return Activity(state: state ?? .working, lastUserPreview: lastInput ?? "",
                        diagnostic: diagnostic, stateIsTrusted: trustworthy, scannedLines: scannedLines)
    }

    private static func userText(in event: [String: Any]) -> String? {
        guard event["type"] as? String == "response_item",
              let payload = event["payload"] as? [String: Any],
              payload["type"] as? String == "message", payload["role"] as? String == "user",
              let content = payload["content"] as? [[String: Any]] else { return nil }
        let text = content.filter { $0["type"] as? String == "input_text" }
            .compactMap { $0["text"] as? String }.joined(separator: " ")
        if text.hasPrefix("<environment_context>") { return nil }
        let authoredText: String
        if text.hasPrefix("# Files mentioned by the user:"), let request = text.range(of: "## My request:") {
            authoredText = String(text[request.upperBound...])
        } else { authoredText = text }
        let preview = userInputPreview(authoredText)
        return preview.isEmpty ? nil : preview
    }

    private static func assistantText(in event: [String: Any]) -> String? {
        guard event["type"] as? String == "response_item",
              let payload = event["payload"] as? [String: Any],
              payload["type"] as? String == "message", payload["role"] as? String == "assistant",
              let content = payload["content"] as? [[String: Any]] else { return nil }
        let reply = content.filter { $0["type"] as? String == "output_text" }
            .compactMap { $0["text"] as? String }.joined(separator: " ")
        return reply.isEmpty ? nil : reply
    }

    private static func eventState(in event: [String: Any]) -> TaskState? {
        guard event["type"] as? String == "event_msg", let payload = event["payload"] as? [String: Any],
              let type = payload["type"] as? String else { return nil }
        switch type {
        case "task_started": return .waiting
        case "task_complete": return .ready
        case "turn_aborted": return .working
        default: return nil
        }
    }
}

enum SyntheticAccess {
    static func check(_ url: URL) {
        if let root = ProcessInfo.processInfo.environment["ORBIT_SYNTHETIC_ROOT"] {
            let path = url.standardizedFileURL.resolvingSymlinksInPath().path
            let allowed = URL(fileURLWithPath: root).standardizedFileURL.resolvingSymlinksInPath().path
            precondition(path == allowed || path.hasPrefix(allowed + "/"), "Synthetic reader escaped fixture root")
        }
    }
    static func exists(_ path: String) -> Bool {
        // Decoded Cursor project paths are metadata, never probed outside fixtures.
        if let root = ProcessInfo.processInfo.environment["ORBIT_SYNTHETIC_ROOT"],
           !URL(fileURLWithPath: path).standardizedFileURL.path.hasPrefix(root + "/") { return false }
        check(URL(fileURLWithPath: path))
        return FileManager.default.fileExists(atPath: path)
    }
}

struct BoardSources {
    let cursorRoot: URL
    let qoderRoot: URL
    let codexDatabase: URL
    let defaults: UserDefaults
    var hookURL: URL? = nil
    static var live: BoardSources {
        precondition(!CommandLine.arguments.contains { $0.hasSuffix("-self-test") }, "Self-tests must inject sources")
        return BoardSources(cursorRoot: CursorReader.root, qoderRoot: QoderReader.root,
                            codexDatabase: CodexReader.databaseURL, defaults: .standard)
    }
    static func synthetic(_ directory: URL) -> BoardSources {
        let suite = "orbit.synthetic." + directory.lastPathComponent
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return BoardSources(cursorRoot: directory.appendingPathComponent("cursor"),
                            qoderRoot: directory.appendingPathComponent("qoder"),
                            codexDatabase: directory.appendingPathComponent("codex.sqlite"), defaults: defaults)
    }
}

struct CursorObservation {
    let count: Int
    let state: TaskState
    let modified: Date
}

struct BoardPollRequest {
    let cursorRoot: URL
    let cursorPaths: [String]
    let qoderRoot: URL
    let hookURL: URL
    let codexDatabase: URL
}

struct BoardPollSnapshot {
    var cursor: [CursorSession] = []
    var cursorObservations: [String: CursorObservation] = [:]
    var qoder: [QoderSession] = []
    var hookEvents: [[String: Any]] = []
    var codex: [CodexSession] = []
}

struct BoardPollTicket {
    let generation: UInt64
    let revision: UInt64
}

struct BoardPollMetrics {
    let readMilliseconds: Double
    let mergeMilliseconds: Double
    let savedSnapshots: Int
}

final class BoardModel: ObservableObject {
    @Published private var storedTasks: [BoardTask] = []
    private var batchTasks: [BoardTask]?
    var tasks: [BoardTask] {
        get { batchTasks ?? storedTasks }
        set {
            if batchDepth > 0 { batchTasks = newValue; return }
            guard newValue != storedTasks else { return }
            storedTasks = newValue
            if !loading { revision &+= 1; save() }
        }
        _modify {
            if batchDepth > 0 {
                yield &batchTasks!
            } else {
                var updated = storedTasks
                defer { tasks = updated }
                yield &updated
            }
        }
    }
    @Published private(set) var codexRecentThreads: [CodexRecentThread] = []
    @Published private(set) var isLoadingCodexRecent = false
    @Published private(set) var hasLoadedCodexRecent = false

    private let fileURL: URL
    private let qoderEventsURL: URL
    private let sources: BoardSources
    private var loading = true
    private var revision: UInt64 = 0
    private var persistedTasks: [BoardTask]?
    private var knownValidMainData: Data?
    private var encodedTasks: [UUID: (task: BoardTask, data: Data)] = [:]
    private(set) var lastSaveMilliseconds = 0.0
    private(set) var lastSavePhaseMilliseconds: [String: Double] = [:]
    private var batchDepth = 0
    private var pendingSave = false
    private var pollGeneration: UInt64 = 0
    private(set) var isPolling = false
    private(set) var skippedPolls = 0
    private(set) var discardedPolls = 0
    private(set) var savedSnapshotCount = 0
    private(set) var lastPollMetrics: BoardPollMetrics?
    private var loadBlocked = false
    private var loadedSnapshot = false
    /// Test adapter throws before each filesystem mutation; production uses no adapter.
    private let storageFault: ((String) throws -> Void)?
    @Published private(set) var persistenceError: String?

    init(dataDirectory: URL? = nil, sources: BoardSources? = nil,
         storageFault: ((String) throws -> Void)? = nil) {
        self.sources = sources ?? .live
        self.storageFault = storageFault
        let support = dataDirectory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DeskFocusBoard", isDirectory: true)
        SyntheticAccess.check(support)
        fileURL = support.appendingPathComponent("tasks.json")
        qoderEventsURL = self.sources.hookURL ?? support.appendingPathComponent("qoder-events.jsonl")
        do {
            try storageFault?("create")
            try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
            let mainExists = FileManager.default.fileExists(atPath: fileURL.path)
            let main = try? Data(contentsOf: fileURL)
            let backup = try? Data(contentsOf: support.appendingPathComponent("tasks.json.bak"))
            let saved = main.flatMap { try? JSONDecoder().decode([BoardTask].self, from: $0) }
            let recovered = backup.flatMap { try? JSONDecoder().decode([BoardTask].self, from: $0) }
            if saved != nil { knownValidMainData = main }
            if mainExists && saved == nil {
                try storageFault?("quarantine")
                try FileManager.default.copyItem(at: fileURL, to: support.appendingPathComponent("tasks-unreadable-" + UUID().uuidString + ".json"))
            }
            if let loaded = saved ?? recovered {
                tasks = loaded
                loadedSnapshot = true
                let repaired = Self.normalizedAutoGroups(loaded)
                if saved != nil, (try JSONEncoder().encode(loaded)) != (try JSONEncoder().encode(repaired)) {
                    let repairBackup = support.appendingPathComponent("tasks-before-auto-group-repair.json")
                    if !FileManager.default.fileExists(atPath: repairBackup.path) {
                        try storageFault?("repairBackup")
                        try FileManager.default.copyItem(at: fileURL, to: repairBackup)
                    }
                }
                tasks = repaired
                loading = false
                // Repair/recovery only after the source snapshot is safely retained.
                let changed = (try JSONEncoder().encode(loaded)) != (try JSONEncoder().encode(tasks))
                if saved == nil || changed { save() }
            } else if mainExists || FileManager.default.fileExists(atPath: support.appendingPathComponent("tasks.json.bak").path) {
                loadBlocked = true
                persistenceError = "任务文件无法读取，已保留隔离副本；请恢复有效备份后重试。"
            }
        } catch {
            loadBlocked = true
            persistenceError = "无法加载任务：\(error.localizedDescription)"
        }
        loading = false
        if persistenceError == nil { persistedTasks = tasks }
    }

    func retrySave() {
        if loadBlocked {
            do {
                let directory = fileURL.deletingLastPathComponent()
                try storageFault?("create")
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                let backup = directory.appendingPathComponent("tasks.json.bak")
                let exists = FileManager.default.fileExists(atPath: fileURL.path)
                let main = try? Data(contentsOf: fileURL)
                let saved = main.flatMap { try? JSONDecoder().decode([BoardTask].self, from: $0) }
                let recovered = (try? Data(contentsOf: backup)).flatMap { try? JSONDecoder().decode([BoardTask].self, from: $0) }
                if saved != nil { knownValidMainData = main }
                if exists && saved == nil {
                    try storageFault?("quarantine")
                    try FileManager.default.copyItem(at: fileURL, to: directory.appendingPathComponent("tasks-unreadable-" + UUID().uuidString + ".json"))
                }
                if let loaded = saved ?? recovered {
                    let normalized = Self.normalizedAutoGroups(loaded)
                    let changed = (try JSONEncoder().encode(loaded)) != (try JSONEncoder().encode(normalized))
                    let repairBackup = directory.appendingPathComponent("tasks-before-auto-group-repair.json")
                    if saved != nil && changed && !FileManager.default.fileExists(atPath: repairBackup.path) {
                        try storageFault?("repairBackup")
                        try FileManager.default.copyItem(at: fileURL, to: repairBackup)
                    }
                    let local = tasks
                    loading = true
                    if !loadedSnapshot {
                        tasks = Self.normalizedAutoGroups(local + loaded.filter { candidate in !local.contains { $0.id == candidate.id } })
                        loadedSnapshot = true
                    }
                    loading = false
                } else if exists || FileManager.default.fileExists(atPath: backup.path) {
                    throw NSError(domain: "OrbitStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "请先恢复有效的任务文件或备份。"])
                }
                loadBlocked = false
            } catch {
                persistenceError = "无法恢复任务：\(error.localizedDescription)"
                return
            }
        }
        save()
    }

    private func encodedTaskSnapshot() throws -> Data {
        let encoder = JSONEncoder()
        var result = Data([91])
        var nextCache: [UUID: (task: BoardTask, data: Data)] = [:]
        for (index, task) in tasks.enumerated() {
            let encoded: Data
            if let cached = encodedTasks[task.id], cached.task == task { encoded = cached.data }
            else { encoded = try encoder.encode(task) }
            if index > 0 { result.append(44) }
            result.append(encoded)
            nextCache[task.id] = (task, encoded)
        }
        result.append(93)
        encodedTasks = nextCache // Keep only currently present IDs; this cache is not a persisted-state marker.
        return result
    }

    private func rotateBackup(_ data: Data, to backup: URL) throws {
        let staged = backup.deletingLastPathComponent().appendingPathComponent("tasks-backup-stage-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: staged) }
        try data.write(to: staged)
        try storageFault?("backupReplace")
        guard Darwin.rename(staged.path, backup.path) == 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
        }
    }

    private func save() {
        guard !loading, !loadBlocked else { return }
        if batchDepth > 0 { pendingSave = true; return }
        guard persistedTasks != tasks else { return }
        let saveStarted = Date()
        var phaseStarted = saveStarted
        lastSavePhaseMilliseconds = [:]
        func phase(_ name: String) {
            let now = Date(); lastSavePhaseMilliseconds[name] = now.timeIntervalSince(phaseStarted) * 1000; phaseStarted = now
        }
        defer { lastSaveMilliseconds = Date().timeIntervalSince(saveStarted) * 1000 }
        let backup = fileURL.deletingLastPathComponent().appendingPathComponent("tasks.json.bak")
        do {
            let data = try encodedTaskSnapshot()
            phase("encode")
            let previous = try? Data(contentsOf: fileURL)
            let validPrevious = previous != nil && (previous == knownValidMainData || previous.flatMap { try? JSONDecoder().decode([BoardTask].self, from: $0) } != nil)
            phase("read_validate_previous")
            try storageFault?("write")
            // Stage the complete new snapshot before touching either existing copy.
            let staged = fileURL.deletingLastPathComponent().appendingPathComponent("tasks-stage-" + UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: staged) }
            try data.write(to: staged)
            phase("stage")
            try storageFault?("replace")
            // Both paths share a directory/filesystem; rename atomically replaces the main.
            guard Darwin.rename(staged.path, fileURL.path) == 0 else {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
            }
            knownValidMainData = data
            phase("replace")
            if validPrevious, let previous {
                try storageFault?("backupRotate")
                try rotateBackup(previous, to: backup)
            } else if !FileManager.default.fileExists(atPath: backup.path) {
                try storageFault?("backupRotate")
                try rotateBackup(data, to: backup)
            }
            phase("backup")
            persistedTasks = tasks
            savedSnapshotCount += 1
            persistenceError = nil
        } catch { persistenceError = "任务尚未保存：\(error.localizedDescription)" }
    }

    func performBatch(_ operation: () -> Void) {
        if batchDepth == 0 { batchTasks = storedTasks }
        batchDepth += 1
        defer {
            batchDepth -= 1
            if batchDepth == 0 {
                let updated = batchTasks!
                batchTasks = nil
                pendingSave = false
                tasks = updated
            }
        }
        operation()
    }

    static func readPollSnapshot(_ request: BoardPollRequest) -> BoardPollSnapshot {
        precondition(!Thread.isMainThread, "Scheduled source reads must run in the background")
        let cursor = CursorReader.sessions(root: request.cursorRoot)
        var observations = Dictionary(uniqueKeysWithValues: cursor.map {
            ($0.path, CursorObservation(count: $0.lineCount, state: $0.state, modified: $0.modified))
        })
        // Legacy bound paths can live outside the current project index. Read each missing path once.
        for path in Set(request.cursorPaths) where observations[path] == nil {
            let events = CursorReader.lines(at: path)
            let attributes = try? FileManager.default.attributesOfItem(atPath: path)
            observations[path] = CursorObservation(count: events.count, state: CursorReader.inferredState(in: events),
                                                   modified: attributes?[.modificationDate] as? Date ?? .distantPast)
        }
        return BoardPollSnapshot(cursor: cursor, cursorObservations: observations,
                                 qoder: QoderReader.sessions(root: request.qoderRoot),
                                 hookEvents: CursorReader.lines(at: request.hookURL.path),
                                 codex: CodexReader.sessions(databaseURL: request.codexDatabase))
    }

    func beginPoll() -> BoardPollTicket? {
        precondition(Thread.isMainThread)
        guard !isPolling else { skippedPolls += 1; return nil }
        isPolling = true
        pollGeneration &+= 1
        return BoardPollTicket(generation: pollGeneration, revision: revision)
    }

    func cancelPoll() {
        precondition(Thread.isMainThread)
        pollGeneration &+= 1
        isPolling = false
    }

    @discardableResult
    func commitPollSnapshot(_ snapshot: BoardPollSnapshot, ticket: BoardPollTicket, readMilliseconds: Double = 0) -> Bool {
        precondition(Thread.isMainThread)
        guard ticket.generation == pollGeneration else { discardedPolls += 1; return false }
        defer { isPolling = false }
        guard ticket.revision == revision else { discardedPolls += 1; return false }
        let started = Date()
        let savesBefore = savedSnapshotCount
        performBatch {
            mergeCursor(snapshot.cursor, observations: snapshot.cursorObservations)
            mergeQoderEvents(snapshot.hookEvents, defaults: sources.defaults)
            mergeQoderTranscripts(snapshot.qoder)
            mergeCodex(snapshot.codex)
        }
        lastPollMetrics = BoardPollMetrics(readMilliseconds: readMilliseconds,
                                          mergeMilliseconds: Date().timeIntervalSince(started) * 1000,
                                          savedSnapshots: savedSnapshotCount - savesBefore)
        return true
    }

    func pollInBackground() {
        guard let ticket = beginPoll() else { return }
        let request = BoardPollRequest(cursorRoot: sources.cursorRoot, cursorPaths: tasks.compactMap(\.cursorPath),
                                       qoderRoot: sources.qoderRoot, hookURL: qoderEventsURL,
                                       codexDatabase: sources.codexDatabase)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let start = Date()
            let snapshot = Self.readPollSnapshot(request)
            let duration = Date().timeIntervalSince(start) * 1000
            DispatchQueue.main.async { [weak self] in
                self?.commitPollSnapshot(snapshot, ticket: ticket, readMilliseconds: duration)
            }
        }
    }

    func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.insert(BoardTask(title: trimmed), at: 0)
    }

    func renameTask(_ id: UUID, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        update(id) { task in
            task.title = trimmed
            if task.isAutoGroup { task.isTitleCustomized = true }
        }
    }

    func update(_ id: UUID, _ change: (inout BoardTask) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        change(&tasks[index])
    }

    func setState(_ id: UUID, to state: TaskState) {
        update(id) { task in
            if !task.isConversation { task.completionOverride = state == .done }
            guard task.state != state else { return }
            task.state = state
            task.stateSince = Date()
        }
    }

    func remove(_ id: UUID) {
        for index in tasks.indices {
            if tasks[index].parentID == id {
                tasks[index].parentID = nil
                tasks[index].groupingMode = tasks[index].boundParentIDs.filter { $0 != id }.isEmpty ? .detached : .manual
            }
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
            task.groupingMode = parentID == nil ? .detached : .manual
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
            child.groupingMode = .manual
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
            if task.parentID == nil { task.groupingMode = .manual }
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
                task.groupingMode = task.parentID == nil ? .detached : .manual
            } else {
                task.boundParentIDs.removeAll { $0 == parentID }
                if task.parentID == nil && task.boundParentIDs.isEmpty { task.groupingMode = .detached }
            }
        }
        save()
    }

    func restoreAutomaticGrouping(_ childID: UUID) {
        guard let child = tasks.first(where: { $0.id == childID }), child.isConversation,
              let key = child.projectKey, !key.isEmpty else { return }
        update(childID) { $0.groupingMode = .auto; $0.parentID = nil }
        ensureProjectParent(for: childID, key: key, title: URL(fileURLWithPath: key).lastPathComponent)
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
            guard let self else { return }
            let recent = CodexReader.recentThreads(databaseURL: self.sources.codexDatabase)
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
            if let customized = groups.first(where: { $0.isTitleCustomized }) {
                result[index].title = customized.title
                result[index].isTitleCustomized = true
            } else {
                result[index].title = URL(fileURLWithPath: key).lastPathComponent
            }
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
        guard !key.isEmpty, let child = tasks.first(where: { $0.id == childID }), child.groupingMode == .auto else { return }
        if let parentID = child.parentID,
           let parent = tasks.first(where: { $0.id == parentID }), !parent.isAutoGroup { return }
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

    private func hasNavigationSource(_ task: BoardTask) -> Bool {
        [task.cursorPath, task.qoderSessionID, task.codexThreadID].contains { $0?.isEmpty == false }
    }

    func navigationTarget(for task: BoardTask, now: Date = Date()) -> BoardTask? {
        guard let current = tasks.first(where: { $0.id == task.id }) else { return nil }
        if current.isConversation {
            return validatedNavigationTarget(current, for: task, now: now)
        }
        return visibleChildren(of: current.id, now: now).filter(hasNavigationSource).sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            if $0.lastActivityAt != $1.lastActivityAt { return $0.lastActivityAt > $1.lastActivityAt }
            return $0.id.uuidString < $1.id.uuidString
        }.first
    }

    /// Recheck the selected identity and ownership without substituting another session.
    func validatedNavigationTarget(_ selected: BoardTask, for owner: BoardTask, now: Date = Date()) -> BoardTask? {
        guard let current = tasks.first(where: { $0.id == selected.id }), hasNavigationSource(current),
              current.cursorPath == selected.cursorPath, current.qoderSessionID == selected.qoderSessionID,
              current.codexThreadID == selected.codexThreadID,
              let currentOwner = tasks.first(where: { $0.id == owner.id }) else { return nil }
        if owner.isConversation {
            guard current.id == owner.id, current.cursorPath == owner.cursorPath,
                  current.qoderSessionID == owner.qoderSessionID, current.codexThreadID == owner.codexThreadID else { return nil }
        } else {
            guard !currentOwner.isConversation, current.belongs(to: owner.id), isVisible(current, now: now) else { return nil }
        }
        return current
    }

    func directURL(for task: BoardTask) -> URL? {
        let trimmed = task.link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(),
              ["http", "https", "qoder", "qoder-app", "cursor", "codex"].contains(scheme),
              !["http", "https"].contains(scheme) || url.host != nil else { return nil }
        return url
    }

    func openConversation(for task: BoardTask, now: Date = Date(), opener: ((BoardTask) -> Bool)? = nil) {
        guard let selected = navigationTarget(for: task, now: now),
              let target = validatedNavigationTarget(selected, for: task, now: now) else { return }
        if let opener { _ = opener(target); return }
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
        if !task.isConversation && task.completionOverride { return .done }
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
        let sessions = CursorReader.sessions(root: sources.cursorRoot)
        var observations = Dictionary(uniqueKeysWithValues: sessions.map {
            ($0.path, CursorObservation(count: $0.lineCount, state: $0.state, modified: $0.modified))
        })
        for path in Set(tasks.compactMap(\.cursorPath)) where observations[path] == nil {
            let events = CursorReader.lines(at: path)
            observations[path] = CursorObservation(count: events.count, state: CursorReader.inferredState(in: events), modified: Date())
        }
        performBatch { mergeCursor(sessions, observations: observations) }
    }

    private func mergeCursor(_ incoming: [CursorSession], observations: [String: CursorObservation]) {
        let sessions = Dictionary(uniqueKeysWithValues: incoming.map { ($0.path, $0) })
        for task in tasks where task.cursorPath != nil {
            guard let path = task.cursorPath, let session = sessions[path] else { continue }
            if task.lastUserPreview != session.lastUserPreview { update(task.id) { $0.lastUserPreview = session.lastUserPreview } }
            if task.projectKey != session.projectKey { update(task.id) { $0.projectKey = session.projectKey } }
            ensureProjectParent(for: task.id, key: session.projectKey, title: session.projectTitle)
        }
        for index in tasks.indices {
            guard let path = tasks[index].cursorPath, let observation = observations[path],
                  observation.count > tasks[index].observedLines else { continue }
            tasks[index].observedLines = observation.count
            tasks[index].lastActivityAt = min(observation.modified, Date())
            if tasks[index].state != .done && tasks[index].state != observation.state {
                tasks[index].state = observation.state
                tasks[index].stateSince = Date()
            }
        }
    }

    func pollQoder(defaults suppliedDefaults: UserDefaults? = nil) {
        let defaults = suppliedDefaults ?? sources.defaults
        let events = CursorReader.lines(at: qoderEventsURL.path)
        performBatch { mergeQoderEvents(events, defaults: defaults) }
    }

    private func mergeQoderEvents(_ events: [[String: Any]], defaults: UserDefaults) {
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

    func pollQoderTranscripts(root suppliedRoot: URL? = nil) {
        let root = suppliedRoot ?? sources.qoderRoot
        let sessions = QoderReader.sessions(root: root)
        performBatch { mergeQoderTranscripts(sessions) }
    }

    private func mergeQoderTranscripts(_ sessions: [QoderSession]) {
        guard !sessions.isEmpty else { return }
        var rows = tasks
        let originalCount = rows.count
        var bySession: [String: Int] = [:]
        var byID: [UUID: Int] = [:]
        var automatic: [String: UUID] = [:]
        for index in rows.indices {
            byID[rows[index].id] = index
            if let sessionID = rows[index].qoderSessionID, bySession[sessionID] == nil { bySession[sessionID] = index }
            if rows[index].isAutoGroup && !rows[index].isConversation, let key = rows[index].projectKey,
               automatic[key] == nil { automatic[key] = rows[index].id }
        }
        func ensureParent(_ index: Int, key: String) {
            guard !key.isEmpty && rows[index].groupingMode == .auto else { return }
            if let parentID = rows[index].parentID, let parentIndex = byID[parentID], !rows[parentIndex].isAutoGroup { return }
            let parentID: UUID
            if let existing = automatic[key] { parentID = existing }
            else {
                var parent = BoardTask(title: URL(fileURLWithPath: key).lastPathComponent)
                parent.projectKey = key; parent.isAutoGroup = true
                parentID = parent.id
                byID[parentID] = rows.count; automatic[key] = parentID; rows.append(parent)
            }
            rows[index].parentID = parentID
        }
        let now = Date()
        for session in sessions {
            let index: Int
            if let existing = bySession[session.id] {
                index = existing
                rows[index].projectKey = session.projectKey
                rows[index].lastUserPreview = session.lastUserPreview
                ensureParent(index, key: session.projectKey)
                let hasNewPrompt = session.lastPromptAt.map { $0 > rows[index].stateSince } ?? false
                let missedInterruption = session.wasInterrupted && rows[index].state == .waiting && rows[index].lastActivityAt <= session.modified
                guard session.lineCount != rows[index].qoderObservedLines || (rows[index].state == .done && hasNewPrompt) || missedInterruption else { continue }
                rows[index].qoderObservedLines = session.lineCount
                rows[index].lastActivityAt = min(session.modified, now)
                if (rows[index].state != .done || hasNewPrompt) && rows[index].state != session.state {
                    rows[index].state = session.state; rows[index].stateSince = now
                }
            } else {
                var task = BoardTask(title: session.title)
                task.qoderSessionID = session.id; task.lastUserPreview = session.lastUserPreview
                task.projectKey = session.projectKey; task.qoderObservedLines = session.lineCount
                task.state = session.state; task.stateSince = session.modified; task.lastActivityAt = min(session.modified, now)
                index = rows.count; bySession[session.id] = index; byID[task.id] = index; rows.append(task)
                ensureParent(index, key: session.projectKey)
            }
        }
        tasks = Array(rows.dropFirst(originalCount).reversed()) + Array(rows.prefix(originalCount))
    }

    func mergeCodex(_ sessions: [CodexSession]) {
        precondition(Thread.isMainThread, "Codex model merges must run on the main thread")
        for session in sessions {
            if let index = tasks.firstIndex(where: { $0.codexThreadID == session.id }) {
                let childID = tasks[index].id
                if tasks[index].projectKey != session.projectKey {
                    tasks[index].projectKey = session.projectKey
                }
                ensureProjectParent(for: childID, key: session.projectKey, title: session.projectTitle)
                guard let current = tasks.firstIndex(where: { $0.id == childID }) else { continue }
                if !session.lastUserPreview.isEmpty && tasks[current].lastUserPreview != session.lastUserPreview {
                    tasks[current].lastUserPreview = session.lastUserPreview
                }
                if session.stateIsTrusted && session.modified > tasks[current].lastActivityAt {
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
    @State private var showHiddenRecovery = false
    @State private var now = Date()

    private var skin: BoardSkin { BoardSkin(rawValue: skinRaw) ?? .midnight }
    private var theme: BoardTheme { skin.theme }

    @ViewBuilder private var persistenceStatus: some View {
        if let error = model.persistenceError {
            HStack {
                Text(error).font(.system(size: 11)).foregroundStyle(.red)
                Button("重试保存") { model.retrySave() }
            }.padding(8)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(theme.border.opacity(0.55))
            persistenceStatus
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
        .sheet(isPresented: $showHiddenRecovery) { HiddenRecoverySheet(model: model, now: now) }
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
            Button("找回已隐藏事项") { showHiddenRecovery = true }
                .buttonStyle(.plain)
                .help("隐藏不等于删除；查看隐藏原因并保留显示")
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
    @State private var detailTask: BoardTask?

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
        .sheet(item: $detailTask) { item in TaskDetailsSheet(task: item, model: model) }
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
            Button("查看完整详情") { detailTask = task; menuOpen = false }
            Divider()
            if !task.isConversation && task.completionOverride {
                Button("重新打开主体") { model.setState(task.id, to: .working); menuOpen = false }
            }
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
                if task.groupingMode != .auto {
                    Button("恢复自动归组") { model.restoreAutomaticGrouping(task.id); menuOpen = false }
                }
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
                            HStack(spacing: 6) {
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
                            .help("\(candidate.sourceName) · \(candidate.title)\n\(candidate.projectKey ?? "")")
                            Button { detailTask = candidate } label: { Image(systemName: "info.circle").frame(width: 26, height: 30) }
                                .buttonStyle(.plain)
                                .help("查看完整详情，不绑定会话")
                                .accessibilityLabel("查看完整详情：\(candidate.title)")
                            }
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
    @State private var detailTask: BoardTask?

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
        .sheet(item: $detailTask) { item in TaskDetailsSheet(task: item, model: model) }
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
            Button("查看完整详情") { detailTask = task; menuOpen = false }
            Divider()
            ForEach(TaskState.allCases) { state in
                Button(state.rawValue) { model.setState(task.id, to: state); menuOpen = false }
            }
            Divider()
            ForEach(model.parentCandidates(for: task)) { parent in
                Button("移到：\(parent.title)") { model.assignParent(task.id, to: parent.id); menuOpen = false }
            }
            if task.groupingMode != .auto {
                Button("恢复自动归组") { model.restoreAutomaticGrouping(task.id); menuOpen = false }
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
            self?.model.pollInBackground()
        }
        model.pollInBackground()
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

func runPersistenceSelfTest() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("orbit-storage-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let main = directory.appendingPathComponent("tasks.json")
    let backup = directory.appendingPathComponent("tasks.json.bak")
    let original = [BoardTask(title: "恢复任务一"), BoardTask(title: "恢复任务二")]
    let encoded = try JSONEncoder().encode(original)
    try encoded.write(to: backup)
    try Data("broken".utf8).write(to: main)
    let model = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
    precondition(model.tasks.map(\.id) == original.map(\.id))
    precondition(model.persistenceError == nil)
    let quarantines = try FileManager.default.contentsOfDirectory(atPath: directory.path).filter { $0.hasPrefix("tasks-unreadable-") }
    precondition(quarantines.count == 1)
    precondition(try! Data(contentsOf: directory.appendingPathComponent(quarantines[0])) == Data("broken".utf8))
    model.add("第三项"); model.add("第四项")
    precondition(try! JSONDecoder().decode([BoardTask].self, from: Data(contentsOf: backup)).count == 3)
    precondition(try! JSONDecoder().decode([BoardTask].self, from: Data(contentsOf: main)).count == 4)
    for stage in ["write", "replace", "backupRotate", "backupReplace"] {
        var fail = false
        let tested = BoardModel(dataDirectory: directory, sources: .synthetic(directory), storageFault: { point in
            if fail && point == stage { throw NSError(domain: "SyntheticStorage", code: 1) }
        })
        let count = tested.tasks.count
        let priorBackup = try Data(contentsOf: backup)
        fail = true
        tested.add("故障-" + stage)
        precondition(tested.tasks.count == count + 1 && tested.persistenceError != nil)
        precondition((try? JSONDecoder().decode([BoardTask].self, from: Data(contentsOf: main))) != nil)
        precondition(try! Data(contentsOf: backup) == priorBackup)
        fail = false
        tested.retrySave()
        precondition(tested.persistenceError == nil)
        precondition(try! JSONDecoder().decode([BoardTask].self, from: Data(contentsOf: main)).count == count + 1)
    }
    // Two corruptions retain distinct evidence, and neither can overwrite the valid backup.
    let goodBackup = try Data(contentsOf: backup)
    try Data("broken-again".utf8).write(to: main)
    var failReplace = true
    let recovering = BoardModel(dataDirectory: directory, sources: .synthetic(directory), storageFault: { point in
        if failReplace && point == "replace" { throw NSError(domain: "SyntheticStorage", code: 2) }
    })
    precondition(!recovering.tasks.isEmpty && recovering.persistenceError != nil)
    precondition(try! Data(contentsOf: backup) == goodBackup)
    precondition(try! FileManager.default.contentsOfDirectory(atPath: directory.path).filter { $0.hasPrefix("tasks-unreadable-") }.count == 2)
    failReplace = false
    recovering.retrySave()
    precondition(recovering.persistenceError == nil)
    for stage in ["create", "quarantine"] {
        if stage == "quarantine" { try Data("bad quarantine".utf8).write(to: main) }
        let snapshot = try Data(contentsOf: backup)
        let tested = BoardModel(dataDirectory: directory, sources: .synthetic(directory), storageFault: { point in
            if point == stage { throw NSError(domain: "SyntheticStorage", code: 3) }
        })
        precondition(tested.persistenceError != nil)
        let unreadMain = try? Data(contentsOf: main)
        tested.add("加载失败后的本地编辑")
        precondition((try? Data(contentsOf: main)) == unreadMain)
        precondition(try! Data(contentsOf: backup) == snapshot)
    }
    let repairDirectory = directory.appendingPathComponent("repair")
    try FileManager.default.createDirectory(at: repairDirectory, withIntermediateDirectories: true)
    var autoOne = BoardTask(title: "old auto"); autoOne.isAutoGroup = true; autoOne.projectKey = "/tmp/repair"
    var autoTwo = BoardTask(title: "second auto"); autoTwo.isAutoGroup = true; autoTwo.projectKey = "/tmp/repair"
    let manual = BoardTask(title: "original manual")
    try JSONEncoder().encode([autoOne, autoTwo, manual]).write(to: repairDirectory.appendingPathComponent("tasks.json"))
    var failRepair = true
    let repairing = BoardModel(dataDirectory: repairDirectory, sources: .synthetic(repairDirectory), storageFault: { point in
        if failRepair && point == "repairBackup" { throw NSError(domain: "SyntheticStorage", code: 4) }
    })
    precondition(repairing.persistenceError != nil)
    repairing.renameTask(manual.id, to: "local edit survives retry")
    failRepair = false
    repairing.retrySave()
    precondition(repairing.persistenceError == nil)
    precondition(FileManager.default.fileExists(atPath: repairDirectory.appendingPathComponent("tasks-before-auto-group-repair.json").path))
    let repairRestored = BoardModel(dataDirectory: repairDirectory, sources: .synthetic(repairDirectory))
    precondition(repairRestored.tasks.contains { $0.id == manual.id && $0.title == "local edit survives retry" })
    print("Persistence recovery self-test passed")
}

if CommandLine.arguments.contains("--recovery-ui-self-test") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("orbit-recovery-ui-" + UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let model = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
    let now = Date(timeIntervalSince1970: 2_000_000_000)
    var recentParent = BoardTask(title: "recent"); recentParent.isAutoGroup = true; recentParent.projectKey = directory.appendingPathComponent("recent").path
    var oldParent = BoardTask(title: "old"); oldParent.isAutoGroup = true; oldParent.projectKey = directory.appendingPathComponent("old").path
    var human = BoardTask(title: "完整的很长很长会话名称，具有相似前缀A")
    human.qoderSessionID = "hidden-human"; human.projectKey = recentParent.projectKey; human.parentID = recentParent.id
    human.state = .human; human.lastActivityAt = now.addingTimeInterval(-25 * 3600)
    var older = BoardTask(title: "完整的很长很长会话名称，具有相似前缀B")
    older.codexThreadID = "hidden-old"; older.projectKey = oldParent.projectKey; older.parentID = oldParent.id
    older.state = .ready; older.lastActivityAt = now.addingTimeInterval(-8 * 86400)
    var other = BoardTask(title: "另一条隐藏会话")
    other.qoderSessionID = "hidden-other"; other.projectKey = oldParent.projectKey; other.parentID = oldParent.id
    other.state = .waiting; other.lastActivityAt = older.lastActivityAt
    model.tasks = [recentParent, oldParent, human, older, other]
    precondition(model.isVisible(human, now: human.lastActivityAt.addingTimeInterval(24 * 3600 - 1)))
    precondition(!model.isVisible(human, now: human.lastActivityAt.addingTimeInterval(24 * 3600 + 1)))
    precondition(model.isVisible(oldParent, now: older.lastActivityAt.addingTimeInterval(7 * 86400 - 1)))
    precondition(!model.isVisible(oldParent, now: older.lastActivityAt.addingTimeInterval(7 * 86400 + 1)))
    let hidden = Set(model.hiddenItems(now: now).map(\.id))
    precondition(hidden.contains(human.id) && hidden.contains(oldParent.id))
    precondition(model.hiddenReason(for: human).contains("24小时"))
    precondition(model.hiddenReason(for: oldParent).contains("7天"))
    model.restoreHiddenItem(oldParent.id, now: now)
    for original in [older, other] {
        let restored = model.tasks.first { $0.id == original.id }!
        precondition(restored.isPinned && restored.state == original.state && restored.parentID == original.parentID && restored.boundParentIDs == original.boundParentIDs)
    }
    precondition(model.isVisible(model.tasks.first { $0.id == oldParent.id }!, now: now))
    let reloaded = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
    for _ in 0..<2 {
        let ticket = reloaded.beginPoll()!
        precondition(reloaded.commitPollSnapshot(BoardPollSnapshot(), ticket: ticket))
    }
    precondition(reloaded.tasks.first { $0.id == older.id }!.isPinned && reloaded.tasks.first { $0.id == other.id }!.isPinned)
    precondition(reloaded.tasks.first { $0.id == human.id }!.state == .human)
    print("Recovery/details synthetic model self-test passed (ordinary UI untested)")
} else if CommandLine.arguments.contains("--poll-snapshot-self-test") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("orbit-poll-" + UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let model = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
    model.add("Synthetic owner")
    let parent = model.tasks[0]
    let source = CodexSession(id: "poll-thread", title: "Synthetic session", lastUserPreview: "fixture", state: .waiting,
                              modified: Date(), projectKey: directory.path, projectTitle: "project")
    let snapshot = BoardPollSnapshot(codex: [source])
    let ticket = model.beginPoll()!
    precondition(model.beginPoll() == nil && model.skippedPolls == 1)
    let before = model.savedSnapshotCount
    precondition(model.commitPollSnapshot(snapshot, ticket: ticket))
    precondition(model.savedSnapshotCount == before + 1 && model.lastPollMetrics!.savedSnapshots == 1)
    let unchanged = model.beginPoll()!
    precondition(model.commitPollSnapshot(snapshot, ticket: unchanged))
    precondition(model.lastPollMetrics!.savedSnapshots == 0)
    let child = model.tasks.first { $0.codexThreadID == source.id }!
    for action in 0..<4 {
        let stale = model.beginPoll()!
        switch action {
        case 0: model.renameTask(parent.id, to: "Edited while reading")
        case 1: model.assignParent(child.id, to: nil)
        case 2: model.bindSession(child.id, to: parent.id); model.unbindSession(child.id, from: parent.id)
        default: model.remove(child.id)
        }
        let memory = model.tasks
        let saves = model.savedSnapshotCount
        precondition(!model.commitPollSnapshot(snapshot, ticket: stale))
        precondition(model.tasks == memory && model.savedSnapshotCount == saves)
    }
    let oldGeneration = model.beginPoll()!
    model.cancelPoll()
    let currentGeneration = model.beginPoll()!
    precondition(!model.commitPollSnapshot(snapshot, ticket: oldGeneration) && model.isPolling)
    precondition(model.commitPollSnapshot(BoardPollSnapshot(), ticket: currentGeneration))
    model.pollInBackground()
    let deadline = Date().addingTimeInterval(5)
    while model.isPolling && Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.01)) }
    precondition(!model.isPolling)
    print("Background poll snapshot and batching self-test passed")
} else if CommandLine.arguments.contains("--poll-performance-self-test") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("orbit-poll-perf-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let logs = directory.appendingPathComponent("qoder")
    let project = logs.appendingPathComponent("synthetic-project")
    try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
    let padding = String(repeating: "x", count: 10480)
    let filler = try JSONSerialization.data(withJSONObject: ["type": "metadata", "padding": padding])
    for index in 0..<100 {
        let user: [String: Any] = ["sessionId": "synthetic-\(index)", "cwd": "/synthetic/project-\(index)", "type": "user",
                                   "message": ["content": [["type": "text", "text": "Synthetic prompt \(index)"]]]]
        var data = try JSONSerialization.data(withJSONObject: user); data.append(10)
        for _ in 0..<100 { data.append(filler); data.append(10) }
        try data.write(to: project.appendingPathComponent("\(index).jsonl"))
    }
    let fixtureSources = BoardSources(cursorRoot: directory.appendingPathComponent("cursor"), qoderRoot: logs,
                                     codexDatabase: directory.appendingPathComponent("missing.sqlite"), defaults: BoardSources.synthetic(directory).defaults)
    let model = BoardModel(dataDirectory: directory.appendingPathComponent("storage"), sources: fixtureSources)
    var tasks: [BoardTask] = []
    for index in 0..<100 {
        var parent = BoardTask(title: "Project \(index)"); parent.isAutoGroup = true; parent.projectKey = "/synthetic/project-\(index)"
        var child = BoardTask(title: "Synthetic prompt \(index)"); child.qoderSessionID = "synthetic-\(index)"; child.projectKey = parent.projectKey; child.parentID = parent.id
        tasks += [parent, child]
    }
    model.tasks = tasks
    var reads: [Double] = [], merges: [Double] = [], saves: [Int] = [], persistence: [Double] = [], phases: [[String: Double]] = []
    for _ in 0..<5 {
        model.performBatch {
            for index in model.tasks.indices where model.tasks[index].isConversation {
                model.tasks[index].qoderObservedLines = 0; model.tasks[index].state = .ready
            }
        }
        let request = BoardPollRequest(cursorRoot: fixtureSources.cursorRoot, cursorPaths: [], qoderRoot: logs,
                                       hookURL: directory.appendingPathComponent("empty-hook.jsonl"), codexDatabase: fixtureSources.codexDatabase)
        let semaphore = DispatchSemaphore(value: 0)
        var snapshot = BoardPollSnapshot()
        var readTime = 0.0
        DispatchQueue.global(qos: .utility).async {
            let start = Date(); snapshot = BoardModel.readPollSnapshot(request)
            readTime = Date().timeIntervalSince(start) * 1000; semaphore.signal()
        }
        semaphore.wait() // This synthetic CLI harness measures the background phase separately.
        let ticket = model.beginPoll()!
        precondition(model.commitPollSnapshot(snapshot, ticket: ticket, readMilliseconds: readTime))
        reads.append(readTime); merges.append(model.lastPollMetrics!.mergeMilliseconds); saves.append(model.lastPollMetrics!.savedSnapshots); persistence.append(model.lastSaveMilliseconds); phases.append(model.lastSavePhaseMilliseconds)
        precondition(model.tasks.count == 200 && model.lastPollMetrics!.savedSnapshots == 1)
    }
    let ordered = merges.sorted(); let p95 = ordered.last!
    let output: [String: Any] = ["build": "swiftc debug", "fixture": "100 logs ~1MB each,200 tasks,5 changed polls", "background_read_ms": reads,
                                  "main_merge_ms": merges, "save_calls": saves, "persistence_ms": persistence, "save_phase_ms": phases, "p95_merge_ms": p95, "longest_merge_ms": ordered.last!]
    print(String(data: try JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys]), encoding: .utf8)!)
    fflush(stdout)
    precondition(p95 <= 16 && ordered.last! <= 50 && zip(reads, merges).allSatisfy { $0 + $1 < 5000 })
    print("Background poll performance self-test passed")
} else if CommandLine.arguments.contains("--codex-format-self-test") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("orbit-format-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = directory.appendingPathComponent("thread.jsonl")
    let user: [String: Any] = ["type": "response_item", "payload": ["type": "message", "role": "user", "content": [["type": "input_text", "text": "格式一致"]]]]
    let reply: [String: Any] = ["type": "response_item", "payload": ["type": "message", "role": "assistant", "content": [["type": "output_text", "text": "请确认目录。"]]]]
    let complete: [String: Any] = ["type": "event_msg", "payload": ["type": "task_complete"]]
    for options: JSONSerialization.WritingOptions in [[], [.sortedKeys]] {
        let records = try [user, reply, complete].map { try JSONSerialization.data(withJSONObject: $0, options: options) }
        var text = records.map { String(data: $0, encoding: .utf8)! }.joined(separator: "\n")
        text = text.replacingOccurrences(of: ":", with: ": ").replacingOccurrences(of: ",", with: ", ")
        try text.write(to: file, atomically: true, encoding: .utf8)
        precondition(CodexReader.recentActivity(at: file.path)?.0 == .human)
        precondition(CodexReader.recentActivity(at: file.path)?.1 == "格式一致")
    }
    let started = "{\"type\": \"event_msg\", \"payload\": {\"type\": \"task_started\"}}"
    try (started + "\n{\"type\":\"event_msg\",\"payload\":{\"type\":\"task_complete\"").write(to: file, atomically: true, encoding: .utf8)
    precondition(CodexReader.diagnostic(at: file.path) == .incompleteTail)
    try (started + "\n{\"payload\":{\"type\":\"task_complete\"},\"type\":\"event_msg\"}").write(to: file, atomically: true, encoding: .utf8)
    precondition(CodexReader.recentActivity(at: file.path)?.0 == .ready)
    try "{\"type\":\"session_meta\",\"payload\":{}}".write(to: file, atomically: true, encoding: .utf8)
    precondition(CodexReader.diagnostic(at: file.path) == .irrelevant)
    try "{\"type\":\"event_msg\",\"payload\":{}}".write(to: file, atomically: true, encoding: .utf8)
    precondition(CodexReader.diagnostic(at: file.path) == .unknownStateSchema)
    try FileManager.default.removeItem(at: file)
    precondition(CodexReader.diagnostic(at: file.path) == .readFailure)
    let database = directory.appendingPathComponent("state.sqlite")
    var handle: OpaquePointer?
    precondition(sqlite3_open(database.path, &handle) == SQLITE_OK)
    precondition(sqlite3_exec(handle, "CREATE TABLE threads (id TEXT, name TEXT, title TEXT, cwd TEXT, rollout_path TEXT, updated_at INTEGER, archived INTEGER)", nil, nil, nil) == SQLITE_OK)
    let sql = "INSERT INTO threads VALUES ('trust-test','trust-test','trust-test','\(directory.path)','\(file.path)',\(Int(Date().timeIntervalSince1970)),0)"
    precondition(sqlite3_exec(handle, sql, nil, nil, nil) == SQLITE_OK)
    sqlite3_close(handle)
    try started.write(to: file, atomically: true, encoding: .utf8)
    let model = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
    model.mergeCodex(CodexReader.sessions(databaseURL: database))
    let child = model.tasks.first { $0.codexThreadID == "trust-test" }!
    let activity = child.lastActivityAt
    let validReady = "{\"type\":\"event_msg\",\"payload\":{\"type\":\"task_complete\"}}"
    let unknown = "{\"type\":\"event_msg\",\"payload\":{\"type\":\"task_future_state\"}}"
    for tail in [unknown, "{\"type\":\"event_msg\",\"payload\":"] {
        try (validReady + "\n" + tail).write(to: file, atomically: true, encoding: .utf8)
        let sessions = CodexReader.sessions(databaseURL: database)
        precondition(sessions.count == 1 && !sessions[0].stateIsTrusted)
        model.mergeCodex(sessions)
        precondition(model.tasks.first { $0.id == child.id }!.state == .waiting)
        precondition(model.tasks.first { $0.id == child.id }!.lastActivityAt == activity)
    }
    try (unknown + "\n" + validReady).write(to: file, atomically: true, encoding: .utf8)
    let validAgain = CodexReader.sessions(databaseURL: database)
    precondition(validAgain[0].stateIsTrusted && validAgain[0].state == .ready)
    model.mergeCodex(validAgain)
    precondition(model.tasks.first { $0.id == child.id }!.state == .ready)
    let largePrefix = String(repeating: "{\"type\":\"session_meta\",\"payload\":{\"padding\":\"" + String(repeating: "x", count: 1024) + "\"}}\n", count: 20_000)
    let tailUser = String(data: try JSONSerialization.data(withJSONObject: user), encoding: .utf8)!
    try (largePrefix + tailUser + "\n" + validReady).write(to: file, atomically: true, encoding: .utf8)
    precondition(CodexReader.recentActivity(at: file.path)?.0 == .ready)
    precondition(CodexReader.scannedLineCount(at: file.path) <= 2)
    let missing = directory.appendingPathComponent("missing.sqlite")
    precondition(CodexReader.sessions(databaseURL: missing).isEmpty)
    precondition(CodexReader.databaseDiagnostic(at: missing) == .readFailure)
    print("Codex format and diagnostics self-test passed")
} else if CommandLine.arguments.contains("--pinned-navigation-self-test") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("orbit-navigation-" + UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let model = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
    let now = Date()
    for index in 0..<3 {
        model.mergeCodex([CodexSession(id: "navigation-\(index)", title: "会话\(index)", lastUserPreview: "", state: .ready,
                                      modified: now.addingTimeInterval(Double(-index)), projectKey: directory.path, projectTitle: "project")])
    }
    let parent = model.tasks.first { $0.isAutoGroup }!
    let newest = model.tasks.first { $0.codexThreadID == "navigation-0" }!
    let older = model.tasks.first { $0.codexThreadID == "navigation-1" }!
    let oldest = model.tasks.first { $0.codexThreadID == "navigation-2" }!
    precondition(model.navigationTarget(for: parent, now: now)?.id == newest.id)
    model.update(older.id) { $0.isPinned = true }
    model.update(oldest.id) { $0.isPinned = true }
    precondition(model.navigationTarget(for: parent, now: now)?.id == older.id)
    model.update(oldest.id) { $0.lastActivityAt = older.lastActivityAt }
    let stable = [older.id, oldest.id].sorted { $0.uuidString < $1.uuidString }.first!
    precondition(model.navigationTarget(for: parent, now: now)?.id == stable)
    let selected = model.navigationTarget(for: parent, now: now)!
    var opened: [UUID] = []
    let context = model.tasks
    model.openConversation(for: parent, now: now, opener: { opened.append($0.id); return false })
    precondition(opened == [selected.id] && model.tasks == context)
    model.assignParent(selected.id, to: nil)
    precondition(model.validatedNavigationTarget(selected, for: parent, now: now) == nil)
    model.remove(newest.id)
    precondition(model.navigationTarget(for: newest, now: now) == nil)
    opened = []
    model.openConversation(for: newest, now: now, opener: { opened.append($0.id); return true })
    precondition(opened.isEmpty)
    for child in model.children(of: parent.id) { model.remove(child.id) }
    precondition(model.navigationTarget(for: parent, now: now) == nil)
    model.openConversation(for: parent, now: now, opener: { opened.append($0.id); return true })
    precondition(opened.isEmpty)
    print("Pinned navigation self-test passed")
} else if CommandLine.arguments.contains("--completion-override-self-test") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("orbit-completion-" + UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let model = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
    let session = CodexSession(id: "shared-session", title: "共享会话", lastUserPreview: "合成输入", state: .waiting,
                               modified: Date(), projectKey: directory.path, projectTitle: "project")
    model.mergeCodex([session])
    let child = model.tasks.first { $0.codexThreadID == session.id }!
    let primary = model.tasks.first { $0.isAutoGroup }!
    model.add("共享主体B")
    let extra = model.tasks.first { $0.title == "共享主体B" }!
    model.bindSession(child.id, to: extra.id)
    for parentID in [primary.id, extra.id] {
        model.setState(parentID, to: .done)
        let closed = model.tasks.first { $0.id == parentID }!
        precondition(model.displayState(for: closed) == .done)
        precondition(model.completed.contains { $0.id == parentID })
        precondition(model.tasks.first { $0.id == child.id }!.state == .waiting)
        let other = model.tasks.first { $0.id == (parentID == primary.id ? extra.id : primary.id) }!
        precondition(model.displayState(for: other) == .waiting)
        let newer = CodexSession(id: session.id, title: session.title, lastUserPreview: "新合成活动", state: .human,
                                 modified: Date().addingTimeInterval(1), projectKey: directory.path, projectTitle: "project")
        model.mergeCodex([newer])
        precondition(model.displayState(for: model.tasks.first { $0.id == parentID }!) == .done)
        let restored = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
        precondition(restored.displayState(for: restored.tasks.first { $0.id == parentID }!) == .done)
        model.setState(parentID, to: .working)
        precondition(model.displayState(for: model.tasks.first { $0.id == parentID }!) == .human)
        model.setState(child.id, to: .waiting)
    }
    // Old formats stored the owner's done state but had no explicit completion override.
    let migrationDirectory = directory.appendingPathComponent("legacy-completion")
    try FileManager.default.createDirectory(at: migrationDirectory, withIntermediateDirectories: true)
    var legacyOwner = BoardTask(title: "旧格式已完成主体"); legacyOwner.state = .done
    let sharedOwner = BoardTask(title: "共享的另一个主体")
    var sharedChild = BoardTask(title: "仍在等待的共享会话")
    sharedChild.qoderSessionID = "legacy-shared-waiting"; sharedChild.state = .waiting
    sharedChild.parentID = sharedOwner.id; sharedChild.boundParentIDs = [legacyOwner.id]
    var legacyCompletedSession = BoardTask(title: "旧格式已完成会话")
    legacyCompletedSession.codexThreadID = "legacy-done-session"; legacyCompletedSession.state = .done
    let fixture = try JSONSerialization.jsonObject(with: JSONEncoder().encode([legacyOwner, sharedOwner, sharedChild, legacyCompletedSession])) as! [[String: Any]]
    let oldFormat = fixture.map { row -> [String: Any] in
        var legacy = row; legacy.removeValue(forKey: "completionOverride"); return legacy
    }
    try JSONSerialization.data(withJSONObject: oldFormat).write(to: migrationDirectory.appendingPathComponent("tasks.json"))
    let migrated = BoardModel(dataDirectory: migrationDirectory, sources: .synthetic(migrationDirectory))
    let closedOwner = migrated.tasks.first { $0.id == legacyOwner.id }!
    precondition(closedOwner.completionOverride && migrated.displayState(for: closedOwner) == .done)
    precondition(migrated.tasks.first { $0.id == sharedChild.id }!.state == .waiting)
    precondition(migrated.displayState(for: migrated.tasks.first { $0.id == sharedOwner.id }!) == .waiting)
    precondition(!migrated.tasks.first { $0.id == legacyCompletedSession.id }!.completionOverride)
    precondition(migrated.tasks.first { $0.id == legacyCompletedSession.id }!.state == .done)
    // A present false from the new format remains an explicit reopening/aggregation choice.
    let explicitFalse = try JSONDecoder().decode(BoardTask.self, from: JSONEncoder().encode(legacyOwner))
    precondition(!explicitFalse.completionOverride)
    print("Completion override self-test passed")
} else if CommandLine.arguments.contains("--grouping-intent-self-test") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("orbit-intent-" + UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let model = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
    let session = CodexSession(id: "intent-thread", title: "会话", lastUserPreview: "合成输入", state: .waiting,
                               modified: Date(), projectKey: directory.path, projectTitle: "project")
    model.mergeCodex([session])
    let child = model.tasks.first { $0.codexThreadID == session.id }!
    let parent = model.tasks.first { $0.isAutoGroup }!
    model.renameTask(parent.id, to: "用户自定义主体")
    model.assignParent(child.id, to: nil)
    model.mergeCodex([session]); model.mergeCodex([session])
    precondition(model.tasks.first { $0.id == child.id }!.parentID == nil)
    let restored = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
    restored.mergeCodex([session])
    precondition(restored.tasks.first { $0.id == child.id }!.groupingMode == .detached)
    precondition(restored.tasks.first { $0.id == child.id }!.parentID == nil)
    precondition(restored.tasks.first { $0.id == parent.id }!.title == "用户自定义主体")
    restored.restoreAutomaticGrouping(child.id)
    precondition(restored.tasks.first { $0.id == child.id }!.parentID == parent.id)
    let twice = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
    precondition(twice.tasks.first { $0.id == parent.id }!.title == "用户自定义主体")
    let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
    precondition(try! encoder.encode(BoardModel.normalizedAutoGroups(twice.tasks)) == encoder.encode(twice.tasks))
    print("Grouping intent self-test passed")
} else if CommandLine.arguments.contains("--cache-concurrency-self-test") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("orbit-cache-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let rollout = directory.appendingPathComponent("thread.jsonl")
    let started = "{\"type\":\"event_msg\",\"payload\":{\"type\":\"task_started\"}}\n"
    let completed = "{\"type\":\"event_msg\",\"payload\":{\"type\":\"task_complete\"}}\n"
    try started.write(to: rollout, atomically: true, encoding: .utf8)
    DispatchQueue.concurrentPerform(iterations: 200) { _ in
        precondition(CodexReader.recentActivity(at: rollout.path)?.0 == .waiting)
    }
    try (started + completed).write(to: rollout, atomically: true, encoding: .utf8)
    DispatchQueue.concurrentPerform(iterations: 200) { _ in
        precondition(CodexReader.recentActivity(at: rollout.path)?.0 == .ready)
    }
    print("Codex cache concurrency self-test passed")
} else if CommandLine.arguments.contains("--persistence-self-test") {
    try runPersistenceSelfTest()
} else if CommandLine.arguments.contains("--intentional-failure-self-test") {
    exit(42)
} else if CommandLine.arguments.contains("--reader-symlink-self-test") {
    _ = CursorReader.lines(at: ProcessInfo.processInfo.environment["ORBIT_SYMLINK_ESCAPE"]!)
    exit(0)
} else if CommandLine.arguments.contains("--reader-escape-self-test") {
    _ = CursorReader.sessions(root: URL(fileURLWithPath: ProcessInfo.processInfo.environment["ORBIT_READER_ESCAPE"]!))
    exit(0)
} else if CommandLine.arguments.contains("--cursor-scan") {
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
    let model = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
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
    let restored = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
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
    let model = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
    precondition(FileManager.default.fileExists(atPath: directory.appendingPathComponent("tasks-before-auto-group-repair.json").path))
    precondition(model.tasks.filter { $0.isAutoGroup && $0.projectKey == key }.count == 1)
    model.setState(current.id, to: .done)
    let session = CursorSession(path: directory.appendingPathComponent("new.jsonl").path, title: "再次进入项目", lastUserPreview: "测试",
                                modified: Date(), lineCount: 0, projectKey: key, projectTitle: "project")
    model.importCursor(session)
    precondition(model.tasks.filter { $0.isAutoGroup && $0.projectKey == key }.count == 1)
    precondition(model.tasks.first { $0.cursorPath == session.path }!.parentID == current.id)
    let restored = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
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
    let model = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
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
    let model = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
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
    let restored = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
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
    let model = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
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
    let restored = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
    precondition(restored.tasks.contains { $0.codexThreadID == "test-thread" && $0.lastUserPreview == "第二次输入" })
    let humanReply = "{\"type\":\"response_item\",\"payload\":{\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"output_text\",\"text\":\"请确认你希望使用哪个目录。\"}]}}\n"
    let needsHuman = started + secondInput + humanReply + "{\"type\":\"event_msg\",\"payload\":{\"type\":\"task_complete\"}}\n"
    try needsHuman.write(to: rolloutURL, atomically: true, encoding: .utf8)
    precondition(CodexReader.sessions(databaseURL: databaseURL)[0].state == .human)
    print("Codex self-test passed")
} else if CommandLine.arguments.contains("--grouping-self-test") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("deskfocus-grouping-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    let model = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
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
    let restoredBound = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
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
    let restored = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
    precondition(restored.active.count == 1)
    precondition(restored.children(of: restored.active[0].id).count == 2)
    print("Grouping self-test passed")
} else if CommandLine.arguments.contains("--lifecycle-self-test") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("deskfocus-lifecycle-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    let model = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
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
    precondition(model.navigationTarget(for: parent, now: now)?.id == oldID)
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
    let restored = BoardModel(dataDirectory: directory, sources: .synthetic(directory))
    precondition(restored.tasks.count == model.tasks.count)
    precondition(restored.tasks.contains { $0.id == parent.id && $0.isAutoGroup })

    let cursorAgent = directory.appendingPathComponent("cursor/synthetic/agent-transcripts/live")
    try! FileManager.default.createDirectory(at: cursorAgent, withIntermediateDirectories: true)
    let livePath = cursorAgent.appendingPathComponent("live.jsonl")
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
