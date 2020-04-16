import Vapor

/// Called before your application initializes.
public func configure(_ app: Application) throws {
    // Register routes
    try routes(app)
    
    // Register middleware
}
