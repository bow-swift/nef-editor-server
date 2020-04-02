import Vapor
import BowEffects

final class PlaygroundBookController {
    private let playgroundBook: PlaygroundBook
    private let config: (WebSocket) -> PlaygroundBookConfig
    
    init(playgroundBook: PlaygroundBook, config: @escaping (WebSocket) -> PlaygroundBookConfig) {
        self.playgroundBook = playgroundBook
        self.config = config
    }
    
    func handler(webSocket: WebSocket, request: Request) throws {
        let queue: DispatchQueue = .init(label: String(describing: PlaygroundBookController.self), qos: .userInitiated)
        
        webSocket.onText { socket, text in
            _ = self.playgroundBook.build(command: text)
                .provide(self.config(socket))
                .unsafeRunSyncEither(on: queue)
        }
    }
}
