import Vapor

public func routes(_ app: Application) throws {
    app.webSocket("playgroundBook", onUpgrade: playgroundBookController().handler)
}

private func playgroundBookController() -> PlaygroundBookController {
    PlaygroundBookController(playgroundBook: PlaygroundBookServer(),
                             config: config)
}

private func config(webSocket: WebSocketOutput) -> PlaygroundBookConfig {
    let output = URL(fileURLWithPath: NSTemporaryDirectory())
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    return PlaygroundBookConfig(outputDirectory: output,
                                encoder: encoder,
                                decoder: decoder,
                                webSocket: webSocket)
}
