import Foundation
import nef

struct PlaygroundBookConfig: HasWebSocketOutput, HasCommandCodable {
    let outputDirectory: URL
    let commandDecoder: ResponseDecoder
    let console: PlaygroundBookConsole
    
    var webSocket: WebSocketOutput { self.console.webSocket }
    var commandEncoder: RequestEncoder { self.console.commandEncoder }
    
    init(outputDirectory: URL, encoder: RequestEncoder, decoder: ResponseDecoder, webSocket: WebSocketOutput) {
        self.outputDirectory = outputDirectory
        self.commandDecoder = decoder
        self.console = PlaygroundBookConsole(webSocket: webSocket, encoder: encoder)
    }
}
