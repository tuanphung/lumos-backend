import Vapor
import HTTP

/// Here we have a controller that helps facilitate
/// RESTful interactions with our Users table
final class UserController {
    
}

extension Request {
    /// Create a user from the JSON body
    /// return BadRequest error if invalid
    /// or no JSON
    func user() throws -> User {
        guard let formData = formURLEncoded?.wrapped else { throw Abort.badRequest }
        let json = JSON(formData)
        return try User(json: json)
    }
}

/// Since UserController doesn't require anything to
/// be initialized we can conform it to EmptyInitializable.
///
/// This will allow it to be passed by type.
extension UserController: EmptyInitializable { }
