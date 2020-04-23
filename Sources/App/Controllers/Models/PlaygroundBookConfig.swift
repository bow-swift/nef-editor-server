import Foundation
import nef

struct PlaygroundBookConfig: HasWebSocketOutput, HasCommandCodable {
    let outputDirectory: URL
    let commandDecoder: Decoder
    let console: PlaygroundBookConsole
    let fileManager: FileManager
    
    var webSocket: WebSocketOutput { self.console.webSocket }
    var commandEncoder: Encoder { self.console.commandEncoder }
    
    init(outputDirectory: URL, encoder: Encoder, decoder: Decoder, webSocket: WebSocketOutput, fileManager: FileManager = .default) {
        self.outputDirectory = outputDirectory
        self.commandDecoder = decoder
        self.fileManager = fileManager
        self.console = PlaygroundBookConsole(webSocket: webSocket, encoder: encoder)
    }
}
