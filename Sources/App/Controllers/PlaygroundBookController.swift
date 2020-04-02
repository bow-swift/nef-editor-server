import Vapor
import BowEffects

final class PlaygroundBookController {
    private let playgroundBook: PlaygroundBook
    
    init(playgroundBook: PlaygroundBook) {
        self.playgroundBook = playgroundBook
    }
    
    func handler(webSocket: WebSocket, request: Request) throws {
        let queue: DispatchQueue = .init(label: String(describing: PlaygroundBookController.self), qos: .userInitiated)
        
        return webSocket.onText { socket, text in
            _ = self.playgroundBook.build(command: text, in: webSocket)
                .unsafeRunSyncEither(on: queue)
        }
    }
}
