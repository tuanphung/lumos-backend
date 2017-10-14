import Vapor
import FluentProvider
import HTTP

final class User: Model {
    let storage = Storage()
    
    // MARK: Properties and database keys
    var slackUserID: String
    var slackUserName: String
    var slackUserToken: String
    var created: Date
    var lastModified: Date
    
    /// The column names for `id` and `content` in the database
    struct Keys {
        static let id = "id"
        static let slackUserID = "slack_user_id"
        static let slackUserName = "slack_user_name"
        static let slackUserToken = "slack_user_token"
        static let created = "created"
        static let lastModified = "last_modified"
    }
    
    /// Creates a new Post
    init(slackUserID: String,
         slackUserName: String,
         slackUserToken: String,
         created: Date = Date(),
         lastModified: Date = Date()) {
        self.slackUserID = slackUserID
        self.slackUserName = slackUserName
        self.slackUserToken = slackUserToken
        self.created = created
        self.lastModified = lastModified
    }
    
    convenience init(slackUser: SlackUser) {
        self.init(slackUserID: slackUser.userID, slackUserName: slackUser.userName, slackUserToken: slackUser.token)
    }
    
    // MARK: Fluent Serialization
    
    /// Initializes the Post from the
    /// database row
    init(row: Row) throws {
        slackUserID = try row.get(User.Keys.slackUserID)
        slackUserName = try row.get(User.Keys.slackUserName)
        slackUserToken = try row.get(User.Keys.slackUserToken)
        created = try row.get(User.Keys.created)
        lastModified = try row.get(User.Keys.lastModified)
    }
    
    // Serializes the Post to the database
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(User.Keys.slackUserID, slackUserID)
        try row.set(User.Keys.slackUserName, slackUserName)
        try row.set(User.Keys.slackUserToken, slackUserToken)
        try row.set(User.Keys.created, created)
        try row.set(User.Keys.lastModified, lastModified)
        return row
    }
}

extension User {
    func createUserIfNotExist() throws -> User {
        if let user = try User.makeQuery()
            .filter(User.Keys.slackUserID, .equals, slackUserID)
            .first() {
            return user
        }
        
        print("Slack user \(slackUserName) is not found.")
        print("Creating new user for Slack user \(slackUserName)")
        try self.save()
        return self
    }
}

// MARK: Fluent Preparation

extension User: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Posts
    static func prepare(_ database: Database) throws {
//        try database.create(self) { builder in
//            builder.id()
//            builder.string(Post.Keys.content)
//        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension User: JSONConvertible {
    convenience init(json: JSON) throws {
        self.init(
            slackUserID: try json.get(User.Keys.slackUserID),
            slackUserName: try json.get(User.Keys.slackUserName),
            slackUserToken: try json.get(User.Keys.slackUserToken),
            created: try json.get(User.Keys.created),
            lastModified: try json.get(User.Keys.lastModified)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(User.Keys.id, id)
        try json.set(User.Keys.slackUserID, slackUserID)
        try json.set(User.Keys.slackUserName, slackUserName)
        try json.set(User.Keys.slackUserToken, slackUserToken)
        try json.set(User.Keys.created, created)
        try json.set(User.Keys.lastModified, lastModified)
        return json
    }
}

// MARK: HTTP

// This allows Task models to be returned
// directly in route closures
extension User: ResponseRepresentable { }
