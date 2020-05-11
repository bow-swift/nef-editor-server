import Vapor
import Bow
import BowEffects


/// Make WebSocket conforms to WebSocketOutput
extension WebSocket: WebSocketOutput {
    
    func send<D>(binary: Data) -> EnvIO<D, WebSocketError, Void> {
        EnvIO.invoke { _ in
            guard let message = String(data: binary, encoding: .utf8) else {
                throw WebSocketError.utf8Expected
            }
            
            self.send(message)
        }^
    }
}
