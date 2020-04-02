import Vapor
import nef
import Bow
import BowEffects

final class PlaygroundBookController {
    
    func handler(webSocket: WebSocket, request: Request) throws {
        let queue: DispatchQueue = .init(label: String(describing: PlaygroundBookController.self), qos: .userInitiated)
        let temporalDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let webSocketConfig = WebSocketConfig(webSocket: webSocket, encoder: JSONEncoder())
        let console = PlaygroundBookConsole(config: webSocketConfig)
        
        let playgroundConfig = PlaygroundBookConfig(console: console,
                                                    outputDirectory: temporalDirectory,
                                                    commandDecoder: JSONDecoder(),
                                                    webSocketConfig: webSocketConfig)
        
        webSocket.onText { socket, text in
            _ = self.handle(text: text)
                .report()
                .unsafeRunSyncEither(with: playgroundConfig, on: queue)
        }
    }

    func handle(text: String) -> EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookGenerated> {
        let command = EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookCommand.Incoming>.var()
        let output = EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookGenerated>.var()
        
        return binding(
            command <- self.getCommand(text: text),
             output <- self.buildPlaygroundBook(command: command.get),
        yield: output.get)^
    }
    
    func getCommand(text: String) -> EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookCommand.Incoming> {
        EnvIO { env in
            guard let data = text.data(using: .utf8) else {
                return IO.raiseError(.init(description: "Unsupported message: \(text)", code: "404"))
            }
            
            return env.commandDecoder
                      .safeDecode(PlaygroundBookCommand.Incoming.self, from: data)
                      .mapError { e in PlaygroundBookCommandError(description: "\(e)", code: "404") }
        }
    }
    
    func buildPlaygroundBook(command: PlaygroundBookCommand.Incoming) -> EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookGenerated> {
        func buildPlaygroundBook(for recipe: PlaygroundRecipe) -> EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookGenerated> {
            EnvIO { env in
                let package = recipe.swiftPackage
                return nef.SwiftPlayground.render(packageContent: package.content, name: package.name, output: env.outputDirectory)
                                          .provide(env.console)
                                          .map { url in PlaygroundBookGenerated(name: package.name, url: url) }^
                                          .mapError { e in PlaygroundBookCommandError(description: "\(e)", code: "500") }
            }
        }
        
        switch command {
        case .recipe(let recipe):
            return buildPlaygroundBook(for: recipe)
        case .unsupported:
            return EnvIO.raiseError(.init(description: "Unsupported command: \(command)", code: "404"))^
        }
    }
}
