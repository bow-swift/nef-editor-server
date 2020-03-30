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
        let io = buildPlaygroundBook(for: recipe, console: console)
        io.unsafeRunAsync { either in self.send(either, in: webSocket) }
    }
    
    private func buildPlaygroundBook(for recipe: PlaygroundRecipe, console: nef.Console) -> IO<nef.Error, URL> {
        let package = recipe.swiftPackage
        let tmp = URL(string: "")! // TODO
        
        return nef.SwiftPlayground
            .render(packageContent: package.content, name: package.name, output: tmp)
            .provide(console)
    }
    
    // MARK: senders
    private func send(_ either: Either<nef.Error, URL>, in webSocket: WebSocket) {
        _ = either.mapLeft { error in
            fatalError() // TODO
        }.map { url in
            fatalError() // TODO
        }
    }
    
    private func sendUnsupportedError(in webSocket: WebSocket) {
        let unsupportedError = WebSocketError(description: "Unsupported message", code: "404")
        webSocket.send(.error(unsupportedError))
    }
}
