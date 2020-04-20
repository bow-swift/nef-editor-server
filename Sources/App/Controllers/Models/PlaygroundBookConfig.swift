import Foundation
import nef

struct PlaygroundBookConfig: HasWebSocketOutput, HasCommandCodable {
    let outputDirectory: URL
    let commandDecoder: Decoder
    let console: PlaygroundBookConsole
    
    var webSocket: WebSocketOutput { self.console.webSocket }
    var commandEncoder: Encoder { self.console.commandEncoder }
    
    init(outputDirectory: URL, encoder: Encoder, decoder: Decoder, webSocket: WebSocketOutput) {
        self.outputDirectory = outputDirectory
        self.commandDecoder = decoder
        self.console = PlaygroundBookConsole(webSocket: webSocket, encoder: encoder)
    }
}
