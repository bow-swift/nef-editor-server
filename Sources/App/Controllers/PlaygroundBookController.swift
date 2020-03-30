import Vapor
import nef
import Bow
import BowEffects

final class PlaygroundBookController {
    
    func handler(webSocket: WebSocket, request: Request) throws {
        webSocket.onText { socket, text in self.handle(webSocket: socket, text: text) }
    }
    
    private func handle(webSocket: WebSocket, text: String) {
        guard let data = text.data(using: .utf8),
              let incomingCommand = try? JSONDecoder().decode(PlaygroundBookCommand.Incoming.self, from: data) else {
                sendUnsupportedError(in: webSocket); return
        }
        
        switch incomingCommand {
        case .recipe(let recipe):
            buildRecipe(recipe, webSocket: webSocket)
        case .unsupported:
            sendUnsupportedError(in: webSocket)
        }
    }
    
    // MARK: builders
    private func buildRecipe(_ recipe: PlaygroundRecipe, webSocket: WebSocket) {
        let console = PlaygroundBookConsole(webSocket: webSocket)
        let sender = curry(self.send(in:_:))(webSocket)
        
        buildPlaygroundBook(for: recipe)
            .unsafeRunAsync(with: console, sender)
    }
    
    private func buildPlaygroundBook(for recipe: PlaygroundRecipe) -> EnvIO<nef.Console, nef.Error, PlaygroundBookGenerated> {
        let package = recipe.swiftPackage
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
        
        return nef.SwiftPlayground.render(packageContent: package.content, name: package.name, output: tmp)
            .map(PlaygroundBookGenerated.init(url:))^
    }
    
    // MARK: senders
    private func send(in webSocket: WebSocket, _ either: Either<nef.Error, PlaygroundBookGenerated>) {
        _ = either.mapLeft { error in
            let socketError = WebSocketError(description: "\(error)", code: "500")
            webSocket.send(.error(socketError))
        }.map { playground in
            webSocket.send(.playgroundBookGenerated(playground))
        }
    }
    
    private func sendUnsupportedError(in webSocket: WebSocket) {
        let unsupportedError = WebSocketError(description: "Unsupported message", code: "404")
        webSocket.send(.error(unsupportedError))
    }
}
