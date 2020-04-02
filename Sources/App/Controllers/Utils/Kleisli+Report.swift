import Vapor
import Bow
import BowEffects

extension Kleisli where F == IOPartial<PlaygroundBookCommandError>, D == PlaygroundBookConfig, A == PlaygroundBookGenerated {
    
    func report() -> EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookGenerated> {
        foldMTap(
            { e in
                self.reportError(e).contramap(\PlaygroundBookConfig.webSocketConfig)
            },
            { playground in
                self.reportSuccess(playground).contramap(\PlaygroundBookConfig.webSocketConfig)
            }
        )
    }
}

extension Kleisli {
    
    func send<C: Encodable>(command: C) -> EnvIO<WebSocketConfig, WebSocketError, Void> {
        let data = EnvIO<WebSocketConfig, WebSocketError, Data>.var()
        let env = EnvIO<WebSocketConfig, WebSocketError, WebSocketConfig>.var()
        
        return binding(
               env <- .ask(),
              data <- env.get.encoder.safeEncode(command).mapError { e in WebSocketError.encoding(error: e) }.env(),
                   |<-env.get.webSocket.send(binary: data.get),
        yield: ())^
    }
    
    private func reportError(_ error: PlaygroundBookCommandError) -> EnvIO<WebSocketConfig, PlaygroundBookCommandError, Void> {
        send(command: PlaygroundBookCommand.Outgoing.error(error))
                 .mapError { e in .init(description: "\(e)", code: "500") }
    }

    private func reportSuccess(_ playground: PlaygroundBookGenerated) -> EnvIO<WebSocketConfig, PlaygroundBookCommandError, Void> {
        send(command: PlaygroundBookCommand.Outgoing.playgroundBookGenerated(playground))
                 .mapError { e in .init(description: "\(e)", code: "500") }
    }
}


extension Kleisli {
    func foldMTap<E: Error, B>(_ f: @escaping (E) -> EnvIO<D, E, B>,
                               _ g: @escaping (A) -> EnvIO<D, E, B>) -> EnvIO<D, E, A> where F == IOPartial<E> {
        flatTap(g).handleErrorWith { e in
            f(e).followedBy(.raiseError(e))
        }^
    }
}
