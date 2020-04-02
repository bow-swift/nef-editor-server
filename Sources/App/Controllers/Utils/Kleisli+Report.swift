import Vapor
import Bow
import BowEffects

extension Kleisli where F == IOPartial<PlaygroundBookCommandError>, D == PlaygroundBookConfig, A == PlaygroundBookGenerated {
    
    func report() -> EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookGenerated> {
        foldMTap(
            { e in
                self.reportError(e)
            },
            { playground in
                self.reportSuccess(playground)
            }
        )
    }
    
    private func reportError(_ error: PlaygroundBookCommandError) -> EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, Void> {
        let env = EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookConfig>.var()
        
        return binding(
            env <- .ask(),
            |<-env.get.console.send(command: PlaygroundBookCommand.Outgoing.error(error))
                .contramap(\PlaygroundBookConfig.webSocketConfig)
                .mapError { e in .init(description: "\(e)", code: "500") },
        yield: ())^
    }

    private func reportSuccess(_ playground: PlaygroundBookGenerated) -> EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, Void> {
        let env = EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookConfig>.var()
        
        return binding(
            env <- .ask(),
            |<-env.get.console.send(command: PlaygroundBookCommand.Outgoing.playgroundBookGenerated(playground))
                .contramap(\PlaygroundBookConfig.webSocketConfig)
                .mapError { e in .init(description: "\(e)", code: "500") },
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
