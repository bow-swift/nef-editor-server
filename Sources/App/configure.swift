import Vapor

/// Called before your application initializes.
public func configure(_ app: Application) throws {
    // Register routes
    try routes(app)
    
    // Register middleware
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory)) // Serves files from `Public/` directory
}
