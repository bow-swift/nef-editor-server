import Foundation
import BowEffects
import nef
import NefEditorData

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


typealias PlaygroundBookResource = IOResource<PlaygroundBookError, URL>

extension PlaygroundBookConfig {
    var resource: PlaygroundBookResource {
        PlaygroundBookResource.from(acquire: {
            let output = self.outputDirectory.appendingPathComponent(UUID().uuidString)
            return .pure(output)
        }, release: { url, _ in
            self.fileManager.removeItemIO(at: url).ignoreError()
        })
    }
}
