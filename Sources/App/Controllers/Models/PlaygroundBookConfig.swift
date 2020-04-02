import Foundation
import nef

struct PlaygroundBookConfig {
    let outputDirectory: URL
    let commandDecoder: ResponseDecoder
    let console: nef.Console & WebSocketCommandOutput
    let webSocketConfig: WebSocketConfig
    
    init(outputDirectory: URL, encoder: RequestEncoder, decoder: ResponseDecoder, webSocket: WebSocketOutput) {
        self.webSocketConfig = WebSocketConfig(webSocket: webSocket, encoder: encoder)
        self.console = PlaygroundBookConsole(config: webSocketConfig)
        self.outputDirectory = outputDirectory
        self.commandDecoder = decoder
    }
}
