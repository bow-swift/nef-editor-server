import Vapor

public func routes(_ wss: NIOWebSocketServer) throws {
    let playgroundBook = PlaygroundBookServer(output: URL(fileURLWithPath: NSTemporaryDirectory()),
                                              encoder: JSONEncoder(),
                                              decoder: JSONDecoder())
    
    wss.get("playground", use: PlaygroundBookController(playgroundBook: playgroundBook).handler)
}
