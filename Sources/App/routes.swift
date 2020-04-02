import Vapor

public func routes(_ wss: NIOWebSocketServer) throws {
    let playgroundBookController = PlaygroundBookController()
    wss.get("playground", use: playgroundBookController.handler)
}
