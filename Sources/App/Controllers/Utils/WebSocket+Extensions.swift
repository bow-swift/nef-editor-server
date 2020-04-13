import Vapor
import Bow
import BowEffects


/// Make WebSocket conforms to WebSocketOutput
extension WebSocket: WebSocketOutput {
    
    func send<D>(binary: Data) -> EnvIO<D, WebSocketError, Void> {
        EnvIO.async { callback in
            guard let message = String(data: binary, encoding: .utf8) else {
                callback(.left(WebSocketError.sending(data: binary)))
                return
            }
            
            let promise = self.eventLoop.makePromise(of: Void.self)
            promise.futureResult.whenFailure { error in
                callback(.left(WebSocketError.sending(error: error)))
            }
            promise.futureResult.whenSuccess {
                callback(.right(()))
            }
            
            self.send(message, promise: promise)
        }^
    }
}
