import Vapor
import Bow
import BowEffects

extension Kleisli where D == PlaygroundBookConfig, F == IOPartial<PlaygroundBookCommandError>, A == PlaygroundBookGenerated {
    
    func report() -> EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, Void> {
        foldM(
            { e in
                WebSocket.send(PlaygroundBookCommand.Outgoing.error(e))
                         .contramap(\PlaygroundBookConfig.webSocketConfig)
                         .mapError { e in .init(description: "\(e)", code: "500") }
            },
            { playground in
                WebSocket.send(PlaygroundBookCommand.Outgoing.playgroundBookGenerated(playground))
                         .contramap(\PlaygroundBookConfig.webSocketConfig)
                         .mapError { e in .init(description: "\(e)", code: "500") }
            }
        )
    }
}
