import Vapor

extension WebSocket {
    func send(_ command: PlaygroundBookCommand.Outgoing) {
        guard let data = try? JSONEncoder().encode(command),
              let socketMessage = String(data: data, encoding: .utf8) else {
            return
        }
        
        send(socketMessage)
    }
}
