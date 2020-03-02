import Vapor

class WebSocketHandler {
    static func handle(webSocket: WebSocket, text: String) {
        let unsupportedError = WebSocketError(description: "Unsupported message", code: "404")
        guard let data = text.data(using: .utf8),
            let incomingCommand = try? JSONDecoder().decode(WebSocketCommand.Incoming.self, from: data) else {
                webSocket.send(.error(unsupportedError))
                return
        }
        
        switch incomingCommand {
        case .recipe(_):
            // TODO: Use nef to generate the playground book. 
            webSocket.send(.status(.init(status: "Starting playground generation")))
            
            sleep(3)
            
            webSocket.send(.status(.init(status: "Progress 50%")))
            
            sleep(4)

            webSocket.send(.playgroundGenerated(.init(url: "http://www.47deg.com")))
            
        case .unsupported:
            webSocket.send(.error(unsupportedError))
        }
    }
}

extension WebSocket {
    func send(_ command: WebSocketCommand.Outgoing) {
        guard let data = try? JSONEncoder().encode(command), let socketMessage = String(data: data, encoding: .utf8) else {
            return
        }
        
        send(socketMessage)
    }
}
