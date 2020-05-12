import Vapor
import Bow
import BowEffects
import NefEditorData

final class PlaygroundBookController {
    private let playgroundBook: PlaygroundBook
    private let config: PlaygroundBookConfig
    private let socketConfig: (WebSocket) -> PlaygroundBookSocketConfig
    private var queue: DispatchQueue { .init(label: String(describing: PlaygroundBookController.self), qos: .userInitiated) }
    
    init(playgroundBook: PlaygroundBook, config: PlaygroundBookConfig, socketConfig: @escaping (PlaygroundBookConfig, WebSocket) -> PlaygroundBookSocketConfig) {
        self.playgroundBook = playgroundBook
        self.config = config
        self.socketConfig = config |> socketConfig
    }
    
    func handle(request: Request, webSocket: WebSocket) {
        webSocket.onText { socket, text in
            _ = self.playgroundBook.build(command: text)
                .provide(self.socketConfig(socket))
                .unsafeRunSyncEither(on: self.queue)
        }
    }
    
    func handle(request: Request) throws -> String {
        try run(request: request)
            .unsafeRunSync(with: config, on: queue)
    }
    
    // MARK: - private methods
    private func run(request: Request) -> EnvIO<PlaygroundBookConfig, PlaygroundBookError, String> {
        let env = EnvIO<PlaygroundBookConfig, PlaygroundBookError, PlaygroundBookConfig>.var()
        let body = EnvIO<PlaygroundBookConfig, PlaygroundBookError, PlaygroundRecipe>.var()
        let response = EnvIO<PlaygroundBookConfig, PlaygroundBookError, PlaygroundBookGenerated>.var()
        let encoded = EnvIO<PlaygroundBookConfig, PlaygroundBookError, String>.var()

        return binding(
                env <- .ask(),
               body <- self.decodeRequest(body: request.body),
           response <- self.playgroundBook.build(recipe: body.get),
            encoded <- self.encodeResponse(response.get),
        yield: encoded.get)^
    }
    
    private func getCommand(text: String) -> EnvIO<PlaygroundBookSocketConfig, PlaygroundBookError, PlaygroundBookCommand.Incoming> {
        guard let data = text.data(using: .utf8) else {
            return .raiseError(PlaygroundBookError.commandCodification)^
        }
            
        let env = EnvIO<PlaygroundBookSocketConfig, PlaygroundBookError, PlaygroundBookSocketConfig>.var()
        let command = EnvIO<PlaygroundBookSocketConfig, PlaygroundBookError, PlaygroundBookCommand.Incoming>.var()
        
        return binding(
            env <- .ask(),
            command <- env.get.commandDecoder
                              .safeDecode(PlaygroundBookCommand.Incoming.self, from: data)
                              .mapError(PlaygroundBookError.invalidCommand),
        yield: command.get)^
    }
    
    private func buildPlaygroundBook(command: PlaygroundBookCommand.Incoming) -> EnvIO<PlaygroundBookSocketConfig, PlaygroundBookError, PlaygroundRecipe> {
        switch command {
        case .recipe(let recipe):
            return .pure(recipe)^
        case .unsupported:
            return .raiseError(PlaygroundBookError.unsupportedCommand)^
        }
    }
    
    private func decodeRequest(body: Request.Body) -> EnvIO<PlaygroundBookConfig, PlaygroundBookError, PlaygroundRecipe> {
        EnvIO.accessM { env in
            guard let data = body.string?.data(using: .utf8) else {
                return .raiseError(.commandCodification)^
            }
            
            return env.requestDecoder.safeDecode(PlaygroundRecipe.self, from: data)
                .mapError(PlaygroundBookError.invalidCommand)
        }
    }

    private func encodeResponse(_ response: PlaygroundBookGenerated) -> EnvIO<PlaygroundBookConfig, PlaygroundBookError, String> {
        EnvIO.accessM { env in
            env.responseEncoder.safeEncode(response)
                .mapError(PlaygroundBookError.invalidCodification)
        }
    }
}

extension PlaygroundBookError: AbortError {
    var status: HTTPResponseStatus { .internalServerError }
    var reason: String { "\(self)" }
}
