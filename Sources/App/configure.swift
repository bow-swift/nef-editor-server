import Vapor

/// Called before your application initializes.
public func configure(_ app: Application) throws {
    // Register routes
    let register = RouteRegister(app: app)
    register.playgroundBook(config: config)
    register.appleSignIn()
    
    // Register middleware
}


// MARK: Builders
private func config(webSocket: WebSocketOutput) -> PlaygroundBookConfig {
    let output = URL(fileURLWithPath: NSTemporaryDirectory())
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    return PlaygroundBookConfig(outputDirectory: output,
                                encoder: encoder,
                                decoder: decoder,
                                webSocket: webSocket)
}
