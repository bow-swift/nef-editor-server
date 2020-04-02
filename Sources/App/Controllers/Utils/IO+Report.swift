import Vapor
import Bow
import BowEffects

extension IO where E == PlaygroundBookCommandError, A == PlaygroundBookGenerated {
    
    func report(withConfig config: WebSocketConfig) -> IO<E, A> {
        foldMTap(
            { e in
                self.reportError(e, config: config)
            },
            { playground in
                self.reportSuccess(playground, config: config)
            }
        )
    }
    
    private func reportError(_ error: E, config: WebSocketConfig) -> IO<E, Void> {
        WebSocket.send(command: PlaygroundBookCommand.Outgoing.error(error))
                 .provide(config)
                 .mapError { e in .init(description: "\(e)", code: "500") }
    }
    
    private func reportSuccess(_ playground: PlaygroundBookGenerated, config: WebSocketConfig) -> IO<E, Void> {
        WebSocket.send(command: PlaygroundBookCommand.Outgoing.playgroundBookGenerated(playground))
                 .provide(config)
                 .mapError { e in .init(description: "\(e)", code: "500") }
    }
}


extension IO {
    func foldMTap<B>(_ f: @escaping (E) -> IO<E, B>,
                     _ g: @escaping (A) -> IO<E, B>) -> IO<E, A> {
        flatTap(g).handleErrorWith { e in
            f(e).followedBy(.raiseError(e))
        }^
    }
}
