import Vapor

let taskController = TaskController()

extension Droplet {
    func setupRoutes() throws {
        get("info") { req in
            return req.description
        }
        
        post("task-reminder/receiver", handler: taskController.slackReceiver)
        try resource("tasks", TaskController.self)
    }
}
