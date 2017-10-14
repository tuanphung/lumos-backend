import Vapor
import FluentProvider
import HTTP

enum TaskStatus: String {
    case ToDo, InProgress, Done
    
    init(rawValue: String) {
        switch rawValue {
            case "ToDo": self = .ToDo
            case "InProgress": self = .InProgress
            case "Done": self = .Done
            default: self = .ToDo
        }
    }
}

final class Task: Model {
    let storage = Storage()
    
    // MARK: Properties and database keys
    var content: String
    var status: TaskStatus
    var creatorID: Int = 0
    var created: Date = Date()
    var lastModified: Date = Date()
    
    /// The column names for `id` and `content` in the database
    struct Keys {
        static let id = "id"
        static let content = "content"
        static let status = "status"
        static let creatorID = "creator_id"
        static let created = "created"
        static let lastModified = "last_modified"
    }
    
    /// Creates a new task
    init(content: String,
         status: TaskStatus,
         creatorID: Int) {
        self.content = content
        self.status = status
        self.creatorID = creatorID
    }
    
    // MARK: Fluent Serialization
    
    /// Initializes the Task from the
    /// database row
    init(row: Row) throws {
        content = try row.get(Task.Keys.content)
        status = try TaskStatus(rawValue: row.get(Task.Keys.status))
        creatorID = try row.get(Task.Keys.creatorID)
        created = try row.get(Task.Keys.created)
        lastModified = try row.get(Task.Keys.lastModified)
    }
    
    // Serializes the Task to the database
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Task.Keys.content, content)
        try row.set(Task.Keys.status, status.rawValue)
        try row.set(Task.Keys.creatorID, creatorID)
        try row.set(Task.Keys.created, created)
        try row.set(Task.Keys.lastModified, lastModified)
        return row
    }
}

// MARK: Fluent Preparation

extension Task: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Tasks
    static func prepare(_ database: Database) throws {
//        try database.create(self) { builder in
//            builder.id()
//            builder.string(Task.Keys.text)
//            builder.string(Task.Keys.status)
//            builder.string(Task.Keys.created)
//            builder.string(Task.Keys.lastModified)
//        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Task: JSONConvertible {
    convenience init(json: JSON) throws {
        self.init(
            content: try json.get(Task.Keys.content),
            status: try TaskStatus(rawValue: json.get(Task.Keys.status)),
            creatorID: try json.get(Task.Keys.creatorID)
        )
    }

    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Task.Keys.id, id)
        try json.set(Task.Keys.content, content)
        try json.set(Task.Keys.status, status.rawValue)
        try json.set(Task.Keys.creatorID, creatorID)
        try json.set(Task.Keys.created, created)
        try json.set(Task.Keys.lastModified, lastModified)
        return json
    }
}

// MARK: HTTP

// This allows Task models to be returned
// directly in route closures
extension Task: ResponseRepresentable { }

// This allows the Task model to be updated
// dynamically by the request.
extension Task: Updateable {
    // Updateable keys are called when `task(for: req)` is called.
    // Add as many updateable keys as you like here.
    public static var updateableKeys: [UpdateableKey<Task>] {
        return [
            // If the request contains a String at key "content"
            // the setter callback will be called.
            UpdateableKey(Task.Keys.content, String.self) { task, content in
                task.content = content
            }
        ]
    }
}
