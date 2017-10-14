import Vapor

//token=gIkuvaNzQIHg97ATvDxqgjtO
//team_id=T0001
//team_domain=example
//enterprise_id=E0001
//enterprise_name=Globular%20Construct%20Inc
//channel_id=C2147483705
//channel_name=test
//user_id=U2147483697
//user_name=Steve
//command=/weather
//text=94070
//response_url=https://hooks.slack.com/commands/1234/5678
//trigger_id=13345224609.738474920.8088930838d88f008e0

enum SlackSubCommand {
    case list, add, assign, unknown
}

final class SlackSlashCommand: JSONConvertible {
    let token: String
    let teamID: String
    let teamDomain: String
    let enterpriseID: String
    let enterpriseName: String
    let channelID: String
    let channelName: String
    let userID: String
    let userName: String
    let command: String
    let text: String
    let responseURL: String
    let triggerID: String
    
    struct Keys {
        static let token = "token"
        static let teamID = "team_id"
        static let teamDomain = "team_domain"
        static let enterpriseID = "enterprise_id"
        static let enterpriseName = "enterprise_name"
        static let channelID = "channel_id"
        static let channelName = "channel_name"
        static let userID = "user_id"
        static let userName = "user_name"
        static let command = "command"
        static let text = "text"
        static let responseURL = "response_url"
        static let triggerID = "trigger_id"
    }
    
    init(token: String,
         teamID: String,
         teamDomain: String,
         enterpriseID: String,
         enterpriseName: String,
         channelID: String,
         channelName: String,
         userID: String,
         userName: String,
         command: String,
         text: String,
         responseURL: String,
         triggerID: String) {
        self.token = token
        self.teamID = teamID
        self.teamDomain = teamDomain
        self.enterpriseID = enterpriseID
        self.enterpriseName = enterpriseName
        self.channelID = channelID
        self.channelName = channelName
        self.userID = userID
        self.userName = userName
        self.command = command
        self.text = text
        self.responseURL = responseURL
        self.triggerID = triggerID
    }
    
    convenience init(json: JSON) throws {
        self.init(
            token: try json.get(SlackSlashCommand.Keys.token),
            teamID: try json.get(SlackSlashCommand.Keys.teamID) ?? "",
            teamDomain: try json.get(SlackSlashCommand.Keys.teamDomain) ?? "",
            enterpriseID: try json.get(SlackSlashCommand.Keys.enterpriseID) ?? "",
            enterpriseName: try json.get(SlackSlashCommand.Keys.enterpriseName) ?? "",
            channelID: try json.get(SlackSlashCommand.Keys.channelID) ?? "",
            channelName: try json.get(SlackSlashCommand.Keys.channelName) ?? "",
            userID: try json.get(SlackSlashCommand.Keys.userID),
            userName: try json.get(SlackSlashCommand.Keys.userName),
            command: try json.get(SlackSlashCommand.Keys.command),
            text: try json.get(SlackSlashCommand.Keys.text),
            responseURL: try json.get(SlackSlashCommand.Keys.responseURL),
            triggerID: try json.get(SlackSlashCommand.Keys.triggerID) ?? ""
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(SlackSlashCommand.Keys.token, token)
        try json.set(SlackSlashCommand.Keys.teamID, teamID)
        try json.set(SlackSlashCommand.Keys.teamDomain, teamDomain)
        try json.set(SlackSlashCommand.Keys.enterpriseID, enterpriseID)
        try json.set(SlackSlashCommand.Keys.enterpriseName, enterpriseName)
        try json.set(SlackSlashCommand.Keys.channelID, channelID)
        try json.set(SlackSlashCommand.Keys.channelName, channelName)
        try json.set(SlackSlashCommand.Keys.userID, userID)
        try json.set(SlackSlashCommand.Keys.userName, userName)
        try json.set(SlackSlashCommand.Keys.command, command)
        try json.set(SlackSlashCommand.Keys.text, text)
        try json.set(SlackSlashCommand.Keys.responseURL, responseURL)
        try json.set(SlackSlashCommand.Keys.triggerID, triggerID)
        return json
    }
    
    var subCommand: SlackSubCommand {
        let parts = text.components(separatedBy: .whitespaces)
        
        if (parts.count == 0) {
            return .unknown
        }
        
        let subCommand = parts[0]
        
        switch subCommand.lowercased() {
        case "list":
            return .list
        case "add":
            return .add
        case "assign":
            return .assign
        default:
            return .unknown
        }
    }
    
    var content: String {
        var offset = 0
        
        switch subCommand {
        case .list:
            offset = 4
        case .add:
            offset = 3
        case .assign:
            offset = 6
        default:
            offset = 0
        }
        
        return String(text.suffix(from: String.Index.init(encodedOffset: offset))).trim()
    }
    
    func slackUser() -> SlackUser {
        return SlackUser(token: token, userID: userID, userName: userName)
    }
}

final class SlackUser: JSONConvertible {
    let token: String
    let userID: String
    let userName: String
    
    struct Keys {
        static let token = "token"
        static let userID = "user_id"
        static let userName = "user_name"
    }
    
    init(token: String,
         userID: String,
         userName: String) {
        self.token = token
        self.userID = userID
        self.userName = userName
    }
    
    convenience init(json: JSON) throws {
        self.init(
            token: try json.get(SlackUser.Keys.token),
            userID: try json.get(SlackUser.Keys.userID),
            userName: try json.get(SlackUser.Keys.userName)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(SlackUser.Keys.token, token)
        try json.set(SlackUser.Keys.userID, userID)
        try json.set(SlackUser.Keys.userName, userName)
        return json
    }
}
