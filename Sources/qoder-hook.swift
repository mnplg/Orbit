import Foundation
import Darwin

// Qoder receives no output from this observer. Only the session ID, event name,
// project directory and a short user supplied label are stored on this Mac.
let input = FileHandle.standardInput.readDataToEndOfFile()
guard let object = (try? JSONSerialization.jsonObject(with: input)) as? [String: Any],
      let sessionID = object["session_id"] as? String,
      let eventName = object["hook_event_name"] as? String,
      ["UserPromptSubmit", "Stop"].contains(eventName) else { exit(0) }

let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("DeskFocusBoard", isDirectory: true)
try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
let path = support.appendingPathComponent("qoder-events.jsonl").path
let timestampFormatter = ISO8601DateFormatter()
timestampFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
var event: [String: String] = ["session_id": sessionID, "hook_event_name": eventName,
                                "timestamp": timestampFormatter.string(from: Date())]
if let cwd = object["cwd"] as? String { event["cwd"] = cwd }
if eventName == "UserPromptSubmit", let prompt = object["prompt"] as? String {
    event["prompt_preview"] = String(prompt.replacingOccurrences(of: "\n", with: " ").prefix(90))
}
guard let data = try? JSONSerialization.data(withJSONObject: event),
      let newline = "\n".data(using: .utf8) else { exit(0) }
let fd = open(path, O_WRONLY | O_APPEND | O_CREAT, 0o600)
guard fd >= 0 else { exit(0) }
flock(fd, LOCK_EX)
_ = data.withUnsafeBytes { write(fd, $0.baseAddress, $0.count) }
_ = newline.withUnsafeBytes { write(fd, $0.baseAddress, $0.count) }
flock(fd, LOCK_UN)
close(fd)
