import Vapor
import Bow
import BowEffects
import NefEditorData

extension Kleisli where F == IOPartial<PlaygroundBookError>, D: HasWebSocketOutput & HasCommandEncoder, A == PlaygroundBookGenerated {
    
    func report() -> EnvIO<D, PlaygroundBookError, A> {
        foldMTap(
            { e in
                self.send(command: PlaygroundBookCommand.Outgoing.error(e.commandError))^
            },
            { playground in
                self.send(command: PlaygroundBookCommand.Outgoing.playgroundBookGenerated(playground))^
            }
        )
    }
    
    private func send<C: Encodable>(command: C) -> EnvIO<D, PlaygroundBookError, Void> {
        let env = EnvIO<D, PlaygroundBookError, D>.var()
        
        return binding(
            env <- .ask(),
                |<-env.get.webSocket.send(command: command)
                    .mapError { e in PlaygroundBookError.sending(e) },
        yield: ())^
    }
}


extension Kleisli {
    func foldMTap<E: Swift.Error, B>(_ f: @escaping (E) -> EnvIO<D, E, B>,
                                     _ g: @escaping (A) -> EnvIO<D, E, B>) -> EnvIO<D, E, A> where F == IOPartial<E> {
        flatTap(g).handleErrorWith { e in
            f(e).followedBy(.raiseError(e))
        }^
    }
}

extension Error {
    var commandError: PlaygroundBookCommandError {
        .init(description: "\(self)", code: "500")
    }
}


extension Kleisli where D: HasLogger {
    func loggerM<E: Swift.Error>(_ f: @escaping (E) -> String,
                                 _ g: @escaping (A) -> String) -> EnvIO<D, E, A> where F == IOPartial<E> {
        foldMTap(
            { error in
                EnvIO.access { env in env.logger.error("\(f(error))") }^
            },
            { value in
                EnvIO.access { env in env.logger.info("\(g(value))") }^
            }
        )
    }
    
    func loggerInfo<E: Swift.Error>(_ g: @escaping () -> String) -> EnvIO<D, E, A> where F == IOPartial<E> {
        flatTap(
            { _ in
                EnvIO.access { env in env.logger.info("\(g())") }^
            }
        ).flatTapError(
            { _ in
                EnvIO.access { env in env.logger.info("\(g())") }^
            }
        )^
    }
}
