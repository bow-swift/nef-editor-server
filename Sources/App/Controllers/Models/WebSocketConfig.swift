import Vapor

struct WebSocketConfig {
    let webSocket: WebSocket
    let encoder: WebSocketEncoder
}
