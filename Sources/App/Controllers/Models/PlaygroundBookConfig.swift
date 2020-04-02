import Foundation
import nef

struct PlaygroundBookConfig {
    let console: nef.Console
    let outputDirectory: URL
    let commandDecoder: WebSocketDecoder
    let webSocketConfig: WebSocketConfig
}
