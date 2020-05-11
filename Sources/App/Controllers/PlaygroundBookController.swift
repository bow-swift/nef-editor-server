import Vapor
import Bow
import BowEffects

final class PlaygroundBookController {
    private let playgroundBook: PlaygroundBook
    private let config: (WebSocket) -> PlaygroundBookConfig
    
    init(playgroundBook: PlaygroundBook, config: @escaping (WebSocket) -> PlaygroundBookConfig) {
        self.playgroundBook = playgroundBook
        self.config = config
    }
    
    func handler(request: Request, webSocket: WebSocket) {
        let queue: DispatchQueue = .init(label: String(describing: PlaygroundBookController.self), qos: .userInitiated)
        
        webSocket.onText { socket, text in
            _ = self.playgroundBook.build(command: text)
                .unsafeRunSyncEither(with: self.config(socket), on: queue)
        }
    }
}

extension PlaygroundBookConfig: AbortError {
    var status: HTTPResponseStatus { .internalServerError }
    var reason: String { "\(self)" }
}
