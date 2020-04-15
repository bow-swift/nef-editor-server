import Vapor
import Bow
import BowEffects
import NefEditorData

extension Kleisli where F == IOPartial<PlaygroundBookCommandError>, D: HasWebSocketOutput & HasCommandEncoder, A == PlaygroundBookGenerated {
    
    func report() -> EnvIO<D, PlaygroundBookCommandError, A> {
        foldMTap(
            { e in
                self.send(command: PlaygroundBookCommand.Outgoing.error(e))
            },
            { playground in
                self.send(command: PlaygroundBookCommand.Outgoing.playgroundBookGenerated(playground))
            }
        )
    }
    
    private func send<C: Encodable>(command: C) -> EnvIO<D, PlaygroundBookCommandError, Void> {
        let env = EnvIO<D, PlaygroundBookCommandError, D>.var()
        
        return binding(
            env <- .ask(),
               |<-env.get.webSocket.send(command: command)
                         .mapError { e in PlaygroundBookCommandError(description: "\(e)", code: "500") },
        yield: ())^
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