import Vapor
import nef
import Bow
import BowEffects

final class PlaygroundBookController {
    func handler(webSocket: WebSocket, request: Request) throws {
        webSocket.onText { socket, text in self.handle(webSocket: socket, text: text, eventLoop: request.eventLoop) }
    }
    
    private func handle(webSocket: WebSocket, text: String, eventLoop: EventLoop) {
        guard let data = text.data(using: .utf8),
              let incomingCommand = try? JSONDecoder().decode(PlaygroundBookCommand.Incoming.self, from: data) else {
                sendUnsupportedError(text: text, in: webSocket); return
        }
        
        switch incomingCommand {
        case .recipe(let recipe):
            buildRecipe(recipe, webSocket: webSocket)
        case .unsupported:
            sendUnsupportedError(text: text, in: webSocket)
        }
    }
    
    // MARK: builders
    private func buildRecipe(_ recipe: PlaygroundRecipe) -> EnvIO<WebSocketConfig, WebSocketError, Void> {
        let queue: DispatchQueue = .init(label: String(describing: PlaygroundBookController.self), qos: .userInitiated)
        let console = PlaygroundBookConsole(webSocket: webSocket)
        let either = buildPlaygroundBook(for: recipe).unsafeRunSyncEither(with: console, on: queue)
        send(in: webSocket, either)
    }
    
    private func buildPlaygroundBook(for recipe: PlaygroundRecipe) -> EnvIO<nef.Console, nef.Error, PlaygroundBookGenerated> {
        let package = recipe.swiftPackage
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
        
        return nef.SwiftPlayground.render(packageContent: package.content, name: package.name, output: tmp)
                                  .map { url in .init(name: package.name, url: url) }^
    }
    
    // MARK: senders
    private func send(in webSocket: WebSocket, _ either: Either<nef.Error, PlaygroundBookGenerated>) {
        _ = either.mapLeft { error in
            let socketError = PlaygroundBookCommandError(description: "\(error)", code: "500")
            webSocket.send(.error(socketError))
        }.map { playground in
            webSocket.send(.playgroundBookGenerated(playground))
        }
    }
    
    private func sendUnsupportedError(text: String, in webSocket: WebSocket) {
        let unsupportedError = PlaygroundBookCommandError(description: "Unsupported message: \(text)", code: "404")
        webSocket.send(.error(unsupportedError))
    }
}
