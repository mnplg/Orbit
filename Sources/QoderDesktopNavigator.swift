import AppKit
import ApplicationServices
import SQLite3

/// Drives only Qoder's dedicated session search. Never types into a chat composer.
final class QoderDesktopNavigator {
    static let shared = QoderDesktopNavigator()
    private var busy = false
    private var completion: ((Error?) -> Void)?

    struct Target {
        let id: String
        let title: String
        let cwd: String
    }

    enum Failure: LocalizedError {
        case permission, missingSession, archivedSession, missingApp, unavailableUI, ambiguous, interrupted
        var errorDescription: String? {
            switch self {
            case .permission: return "请在系统设置 → 隐私与安全性 → 辅助功能中允许 Orbit，然后再次点击会话。"
            case .missingSession: return "Qoder 桌面版本机记录中没有找到此会话，无法确认目标。可使用会话菜单中的“在终端恢复（CLI）”。"
            case .archivedSession: return "此会话已归档或删除，请先在 Qoder 中恢复它。"
            case .missingApp: return "未找到 Qoder 桌面版。"
            case .unavailableUI: return "未能在 Qoder 中定位或打开此会话。请确认主窗口可见；界面版本变化也可能影响定位。"
            case .ambiguous: return "搜索结果无法唯一确认目标，已停止，避免打开错误会话。"
            case .interrupted: return "导航过程中搜索内容或前台应用发生变化，已停止自动操作。"
            }
        }
    }

    static let databaseURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/com.qoder.app.stable/main.sqlite")

    static func target(id: String, databaseURL: URL = databaseURL) throws -> Target {
        guard id.range(of: "^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$", options: .regularExpression)
                == id.startIndex..<id.endIndex, !id.isEmpty else { throw Failure.missingSession }
        var db: OpaquePointer?
        guard sqlite3_open_v2(databaseURL.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK, let db else {
            if db != nil { sqlite3_close(db) }
            throw Failure.missingSession
        }
        defer { sqlite3_close(db) }
        sqlite3_busy_timeout(db, 150)
        var statement: OpaquePointer?
        let sql = "SELECT title, cwd, archived, deleted_at FROM chat_sessions WHERE session_id = ?"
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw Failure.missingSession
        }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        guard sqlite3_step(statement) == SQLITE_ROW else { throw Failure.missingSession }
        guard sqlite3_column_int(statement, 2) == 0,
              sqlite3_column_type(statement, 3) == SQLITE_NULL else { throw Failure.archivedSession }
        guard let titleValue = sqlite3_column_text(statement, 0),
              let cwdValue = sqlite3_column_text(statement, 1) else { throw Failure.missingSession }
        let title = String(cString: titleValue), cwd = String(cString: cwdValue)
        guard !title.isEmpty, !cwd.isEmpty else { throw Failure.missingSession }
        // Accessibility exposes result labels, not their session IDs. Reject local
        // duplicate labels even if the current search happens to render only one.
        var duplicate: OpaquePointer?
        let duplicatesSQL = "SELECT COUNT(*) FROM chat_sessions WHERE title = ? AND cwd = ? AND archived = 0 AND deleted_at IS NULL"
        guard sqlite3_prepare_v2(db, duplicatesSQL, -1, &duplicate, nil) == SQLITE_OK, let duplicate else {
            throw Failure.missingSession
        }
        defer { sqlite3_finalize(duplicate) }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(duplicate, 1, title, -1, transient)
        sqlite3_bind_text(duplicate, 2, cwd, -1, transient)
        guard sqlite3_step(duplicate) == SQLITE_ROW, sqlite3_column_int(duplicate, 0) == 1 else {
            throw Failure.ambiguous
        }
        return Target(id: id, title: title, cwd: cwd)
    }

    func open(id: String, completion: ((Error?) -> Void)? = nil) {
        guard !busy else { return }
        self.completion = completion
        do {
            let target = try Self.target(id: id)
            let prompt = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            guard AXIsProcessTrustedWithOptions(prompt) else { throw Failure.permission }
            guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.qoder.app") else {
                throw Failure.missingApp
            }
            busy = true
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: appURL, configuration: config) { [weak self] app, error in
                guard let app, error == nil else {
                    DispatchQueue.main.async { self?.finish(error ?? Failure.missingApp) }
                    return
                }
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try Self.navigate(target: target, pid: app.processIdentifier)
                        DispatchQueue.main.async { self?.finish(nil) }
                    } catch {
                        DispatchQueue.main.async { self?.finish(error) }
                    }
                }
            }
        } catch { finish(error) }
    }

    private func finish(_ error: Error?) {
        busy = false
        if let completion {
            self.completion = nil
            completion(error)
            return
        }
        guard let error else { return }
        let alert = NSAlert()
        alert.messageText = "未能打开指定的 Qoder 会话"
        alert.informativeText = error.localizedDescription
        if case Failure.permission = error {
            alert.addButton(withTitle: "打开辅助功能设置")
            alert.addButton(withTitle: "稍后")
            if alert.runModal() == .alertFirstButtonReturn,
               let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        } else {
            alert.addButton(withTitle: "知道了")
            alert.runModal()
        }
    }

    private static func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private static func text(_ element: AXUIElement, _ name: String) -> String {
        attribute(element, name) as? String ?? ""
    }

    private static func elements(_ app: AXUIElement) -> [AXUIElement] {
        var stack = (attribute(app, "AXWindows") as? [AXUIElement] ?? []).map { ($0, 0) }
        var result: [AXUIElement] = []
        while let (element, depth) = stack.popLast(), result.count < 4000 {
            result.append(element)
            if depth < 40, let children = attribute(element, "AXChildren") as? [AXUIElement] {
                stack += children.map { ($0, depth + 1) }
            }
        }
        return result
    }

    private static func searchField(in all: [AXUIElement]) -> AXUIElement? {
        all.first { element in
            guard text(element, "AXRole") == "AXTextField" else { return false }
            let placeholder = text(element, "AXPlaceholderValue").lowercased()
            // Match the session-ID search field, never a general text area.
            return placeholder.contains("会话 id") || placeholder.contains("session id")
        }
    }

    static func matchesResult(label: String, target: Target) -> Bool {
        label.hasPrefix(target.title + " ") && label.contains(target.cwd)
    }

    private static func matchesResult(element: AXUIElement, target: Target) -> Bool {
        guard matchesResult(label: text(element, "AXTitle"), target: target) else { return false }
        // An exact title text node distinguishes "Task" from "Task extended".
        var children = attribute(element, "AXChildren") as? [AXUIElement] ?? []
        var visited = 0
        while let child = children.popLast(), visited < 100 {
            visited += 1
            if text(child, "AXRole") == "AXStaticText",
               text(child, "AXValue") == target.title || text(child, "AXTitle") == target.title {
                return true
            }
            children += attribute(child, "AXChildren") as? [AXUIElement] ?? []
        }
        return false
    }

    private static func navigate(target: Target, pid: pid_t) throws {
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 1)
        AXUIElementSetAttributeValue(app, "AXManualAccessibility" as CFString, kCFBooleanTrue)
        let deadline = Date().addingTimeInterval(12)
        var openedSearch = false
        var filled = false
        var selected = false
        var resultSignature = ""
        var stableSince = Date()
        while Date() < deadline {
            if NSWorkspace.shared.frontmostApplication?.processIdentifier != pid {
                if !openedSearch && !filled && deadline.timeIntervalSinceNow > 10 {
                    Thread.sleep(forTimeInterval: 0.1)
                    continue
                }
                throw Failure.interrupted
            }
            let all = elements(app)
            if selected {
                if searchField(in: all) == nil,
                   all.contains(where: { text($0, "AXRole") == "AXHeading" && text($0, "AXTitle") == target.title }) {
                    return
                }
            } else if let field = searchField(in: all) {
                if !filled {
                    guard AXUIElementSetAttributeValue(field, "AXValue" as CFString, target.id as CFString) == .success else {
                        throw Failure.unavailableUI
                    }
                    filled = true
                    stableSince = Date()
                } else {
                    guard text(field, "AXValue") == target.id else { throw Failure.interrupted }
                    let searching = all.contains {
                        let value = text($0, "AXValue")
                        return value == "搜索中…" || value == "Searching…" || value == "Searching..."
                    }
                    if searching {
                        stableSince = Date()
                        Thread.sleep(forTimeInterval: 0.15)
                        continue
                    }
                    let candidates = all.filter {
                        text($0, "AXRole") == "AXButton" && matchesResult(element: $0, target: target)
                    }
                    let signature = candidates.map { text($0, "AXTitle") }.sorted().joined(separator: "\n")
                    if signature != resultSignature {
                        resultSignature = signature
                        stableSince = Date()
                    }
                    // Let debounced search finish; fail closed if multiple results remain.
                    if Date().timeIntervalSince(stableSince) >= 0.8 {
                        if candidates.count > 1 { throw Failure.ambiguous }
                        if let candidate = candidates.first {
                            guard AXUIElementPerformAction(candidate, "AXPress" as CFString) == .success else {
                                throw Failure.unavailableUI
                            }
                            selected = true
                        }
                    }
                }
            } else if !openedSearch,
                      let button = all.first(where: {
                          guard text($0, "AXRole") == "AXButton" else { return false }
                          let title = text($0, "AXTitle")
                          return title.hasPrefix("搜索 ") || title.hasPrefix("Search ")
                      }) {
                guard AXUIElementPerformAction(button, "AXPress" as CFString) == .success else { throw Failure.unavailableUI }
                openedSearch = true
            }
            Thread.sleep(forTimeInterval: 0.15)
        }
        throw Failure.unavailableUI
    }
}
