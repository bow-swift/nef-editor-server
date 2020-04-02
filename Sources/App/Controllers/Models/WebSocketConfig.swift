import Vapor

struct WebSocketConfig {
    let webSocket: WebSocketOutput
    let encoder: RequestEncoder
}
