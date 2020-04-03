import Vapor

public func routes(_ wss: NIOWebSocketServer) throws {
    wss.get("playground", use: PlaygroundBookController(playgroundBook: PlaygroundBookServer(),
                                                        config: config).handler)
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
