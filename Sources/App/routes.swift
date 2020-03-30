import Vapor

public func routes(_ router: Router) throws {
    router.get { req in "It works!" }
    router.get("hello") { req in "Hello, world!" }
}

public func routes(_ wss: NIOWebSocketServer) throws {
    let playgroundBookController = PlaygroundBookController()
    
    wss.get("playground", use: playgroundBookController.handler)
}
