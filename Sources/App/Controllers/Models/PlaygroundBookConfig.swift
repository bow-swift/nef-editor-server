import Foundation
import nef

struct PlaygroundBookConfig {
    let console: nef.Console
    let outputDirectory: URL
    let commandDecoder: ResponseDecoder
    let webSocketConfig: WebSocketConfig
    
    init(outputDirectory: URL, encoder: RequestEncoder, decoder: ResponseDecoder, webSocket: WebSocketOutput) {
        self.outputDirectory = outputDirectory
        self.commandDecoder = decoder
        self.webSocketConfig = WebSocketConfig(webSocket: webSocket, encoder: encoder)
        self.console = PlaygroundBookConsole(config: webSocketConfig)
    }
}
