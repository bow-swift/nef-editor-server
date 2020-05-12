import Vapor

/// Called before your application initializes.
public func configure(_ app: Application) throws {
    // Register routes
    let register = RouteRegister(app: app)
    try register.healthCheck()
    try register.playgroundBook()
    try register.appleSignIn()
    
    // Register middleware
}
