import Vapor

final class PlaygroundBookServer: PlaygroundBook {
    private let output: URL
    private let encoder: RequestEncoder
    private let decoder: ResponseDecoder
    
    init(output: URL, encoder: RequestEncoder, decoder: ResponseDecoder) {
        self.output = output
        self.encoder = encoder
        self.decoder = decoder
    }
    
    func configuration(webSocket: WebSocketOutput) -> PlaygroundBookConfig {
        let webSocketConfig = WebSocketConfig(webSocket: webSocket, encoder: encoder)
        let console = PlaygroundBookConsole(config: webSocketConfig)
        
        return .init(console: console,
                     outputDirectory: output,
                     commandDecoder: decoder,
                     webSocketConfig: webSocketConfig)
    }
}
