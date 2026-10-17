import Foundation
import SQLite3

func runTests() throws {
 let dir=FileManager.default.temporaryDirectory.appendingPathComponent("orbit-desktop-nav-test-\(UUID().uuidString)")
 try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
 defer {try? FileManager.default.removeItem(at:dir)}
 let file=dir.appendingPathComponent("test.sqlite")
 var db:OpaquePointer?;precondition(sqlite3_open(file.path,&db)==SQLITE_OK)
 defer {sqlite3_close(db)}
 func sql(_ value:String) {precondition(sqlite3_exec(db,value,nil,nil,nil)==SQLITE_OK)}
 sql("CREATE TABLE chat_sessions(session_id TEXT,title TEXT,cwd TEXT,archived INTEGER,deleted_at INTEGER)")
 sql("INSERT INTO chat_sessions VALUES('target','Unique title','/tmp/project',0,NULL)")
 let target=try QoderDesktopNavigator.target(id:"target",databaseURL:file)
 precondition(target.id=="target" && target.title=="Unique title")
 precondition(QoderDesktopNavigator.matchesResult(label:"Unique title project · /tmp/project just now",target:target))
 precondition(!QoderDesktopNavigator.matchesResult(label:"Other title project · /tmp/project",target:target))
 precondition(!QoderDesktopNavigator.matchesResult(label:"Unique title project · /tmp/other",target:target))
 for id in ["missing","target' OR 1=1 --","target\n"] {
  do {_ = try QoderDesktopNavigator.target(id:id,databaseURL:file);preconditionFailure("invalid target accepted")}
  catch QoderDesktopNavigator.Failure.missingSession {}
 }
 sql("INSERT INTO chat_sessions VALUES('duplicate','Unique title','/tmp/project',0,NULL)")
 do {_ = try QoderDesktopNavigator.target(id:"target",databaseURL:file);preconditionFailure("duplicate accepted")}
 catch QoderDesktopNavigator.Failure.ambiguous {}
 sql("UPDATE chat_sessions SET archived=1 WHERE session_id='duplicate'")
 _ = try QoderDesktopNavigator.target(id:"target",databaseURL:file)
 sql("UPDATE chat_sessions SET archived=1 WHERE session_id='target'")
 do {_ = try QoderDesktopNavigator.target(id:"target",databaseURL:file);preconditionFailure("archived accepted")}
 catch QoderDesktopNavigator.Failure.archivedSession {}
 sql("UPDATE chat_sessions SET archived=0,deleted_at=1 WHERE session_id='target'")
 do {_ = try QoderDesktopNavigator.target(id:"target",databaseURL:file);preconditionFailure("deleted accepted")}
 catch QoderDesktopNavigator.Failure.archivedSession {}
 print("Desktop navigation metadata and disambiguation tests passed")
}

try runTests()
