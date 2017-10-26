import Vapor
import HTTP

enum TaskError: Error {
    case invalidCreator
    case invalidText
    case generic
}

final class TaskController {
    func slackReceiver(_ req: Request) throws -> ResponseRepresentable {
        guard let formData = req.formURLEncoded?.wrapped else {
            return "EMPTY"
        }
        let json = JSON(formData)
        let slashCommand = try SlackSlashCommand(json: json)
        
        switch slashCommand.subCommand {
        case .list:
            return try getTasks(slashCommand: slashCommand)
        case .add:
            return try addTask(slashCommand: slashCommand)
        case .delete:
            return try deleteTask(slashCommand: slashCommand)
        case .assign:
            return try assignTask(slashCommand: slashCommand)
        default:
            return json
        }
    }
    
    func getTasks(slashCommand: SlackSlashCommand) throws -> ResponseRepresentable {
        guard let user = try User.makeQuery()
            .filter(User.Keys.slackUserID, .equals, slashCommand.slackUser().userID)
            .first() else {
            throw TaskError.generic
        }
        
        let tasks = try Task.makeQuery().filter(Task.Keys.creatorID, .equals, user.id).all()
        
        var json = JSON()
        let attachments = try tasks.map { return try $0.makeSlackAttachment() }
        try json.set("attachments", attachments)
        return json
    }
    
    func addTask(slashCommand: SlackSlashCommand) throws -> ResponseRepresentable {
        let user = try User(slackUser: slashCommand.slackUser()).createUserIfNotExist()
        
        guard let userID = user.id?.int else {
            throw TaskError.invalidCreator
        }
        
        let content = slashCommand.content
        let task = Task(content: content, status: .ToDo, creatorID: userID)
        try task.save()
        
        var json = JSON()
        let attachments = try [task].map { return try $0.makeSlackAttachment() }
        try json.set("attachments", attachments)
        return json
    }
    
    func deleteTask(slashCommand: SlackSlashCommand) throws -> ResponseRepresentable {
        let user = try User(slackUser: slashCommand.slackUser()).createUserIfNotExist()
        
        guard let userID = user.id?.int else {
            throw TaskError.invalidCreator
        }
        
        guard let taskID = slashCommand.content.int else {
            throw TaskError.invalidCreator
        }
        
        let tasks = try Task.makeQuery()
            .filter(Task.Keys.creatorID, .equals, userID)
            .filter(Task.Keys.id, .equals, taskID)
            .all()
        
        try tasks.forEach { (task) in
            try task.delete()
        }
        
        return "Deleted"
    }
    
    func assignTask(slashCommand: SlackSlashCommand) throws -> Task {
        throw TaskError.generic
    }
}

/// Here we have a controller that helps facilitate
/// RESTful interactions with our Tasks table
extension TaskController: ResourceRepresentable {
    /// When users call 'GET' on '/tasks'
    /// it should return an index of all available tasks
    func index(_ req: Request) throws -> ResponseRepresentable {
        return try Task.all().makeJSON()
    }
    
    /// When consumers call 'TASK' on '/tasks' with valid JSON
    /// construct and save the task
    func store(_ req: Request) throws -> ResponseRepresentable {
        let task = try req.task()
        try task.save()
        return task
    }
    
    /// When the consumer calls 'GET' on a specific resource, ie:
    /// '/tasks/13rd88' we should show that specific task
    func show(_ req: Request, task: Task) throws -> ResponseRepresentable {
        return task
    }
    
    /// When the consumer calls 'DELETE' on a specific resource, ie:
    /// 'tasks/l2jd9' we should remove that resource from the database
    func delete(_ req: Request, task: Task) throws -> ResponseRepresentable {
        try task.delete()
        return Response(status: .ok)
    }
    
    /// When the consumer calls 'DELETE' on the entire table, ie:
    /// '/tasks' we should remove the entire table
    func clear(_ req: Request) throws -> ResponseRepresentable {
        try Task.makeQuery().delete()
        return Response(status: .ok)
    }
    
    /// When the user calls 'PATCH' on a specific resource, we should
    /// update that resource to the new values.
    func update(_ req: Request, task: Task) throws -> ResponseRepresentable {
        // See `extension Task: Updateable`
        try task.update(for: req)
        
        // Save an return the updated task.
        try task.save()
        return task
    }
    
    /// When a user calls 'PUT' on a specific resource, we should replace any
    /// values that do not exist in the request with null.
    /// This is equivalent to creating a new Task with the same ID.
    func replace(_ req: Request, task: Task) throws -> ResponseRepresentable {
        // First attempt to create a new Task from the supplied JSON.
        // If any required fields are missing, this request will be denied.
        let new = try req.task()
        
        // Update the task with all of the properties from
        // the new task
        task.content = new.content
        try task.save()
        
        // Return the updated task
        return task
    }
    
    /// When making a controller, it is pretty flexible in that it
    /// only expects closures, this is useful for advanced scenarios, but
    /// most of the time, it should look almost identical to this
    /// implementation
    func makeResource() -> Resource<Task> {
        return Resource(
            index: index,
            store: store,
            show: show,
            update: update,
            replace: replace,
            destroy: delete,
            clear: clear
        )
    }
}

extension Request {
    /// Create a task from the JSON body
    /// return BadRequest error if invalid
    /// or no JSON
    func task() throws -> Task {
        guard let formData = formURLEncoded?.wrapped else { throw Abort.badRequest }
        let json = JSON(formData)
        return try Task(json: json)
    }
}

/// Since TaskController doesn't require anything to
/// be initialized we can conform it to EmptyInitializable.
///
/// This will allow it to be passed by type.
extension TaskController: EmptyInitializable { }

