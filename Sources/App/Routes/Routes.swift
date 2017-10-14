import Vapor

let taskController = TaskController()

extension Droplet {
    func setupRoutes() throws {
        post("task-reminder/receiver", handler: taskController.slackReceiver)

        get("hello") { req in
            var json = JSON()
            try json.set("hello", "world")
            return json
        }

        get("plaintext") { req in
            return "Hello, world!"
        }

        // response to requests to /info domain
        // with a description of the request
        get("info") { req in
            return req.description
        }

        get("description") { req in return req.description }
        
        try resource("posts", PostController.self)
        try resource("tasks", TaskController.self)
    }
}
