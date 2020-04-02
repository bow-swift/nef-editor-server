import Vapor
import Bow
import BowEffects

protocol WebSocketOutput {
    func send(text: String, promise: Promise<Void>)
    func send(text: String)
    func send(binary: Data) -> IO<WebSocketError, Void>
}

extension WebSocketOutput {
    static func send<C: Encodable>(command: C) -> EnvIO<WebSocketConfig, WebSocketError, Void> {
        EnvIO { env in
            let data = IO<WebSocketError, Data>.var()
            
            return binding(
                  data <- env.encoder.safeEncode(command).mapError { e in WebSocketError.encoding(error: e) },
                       |<-env.webSocket.send(binary: data.get),
            yield: ())^
        }
    }
}

/// Make `WebSocket` conforms to `WebSocketOutput`
extension WebSocket: WebSocketOutput {
    func send(text: String, promise: EventLoopPromise<Void>) {
        self.send(text, promise: promise)
    }
    
    func send(text: String) {
        self.send(text, promise: nil)
    }
    
    func send(binary: Data) -> IO<WebSocketError, Void> {
        IO.async { callback in
            guard let message = String(data: binary, encoding: .utf8) else {
                callback(.left(WebSocketError.sending(data: binary)))
                return
            }
            
            let promise: Promise<Void> = self.eventLoop.newPromise()
            promise.futureResult.whenFailure { error in
                callback(.left(WebSocketError.sending(error: error)))
            }
            promise.futureResult.whenSuccess {
                callback(.right(()))
            }
            
            self.send(text: message, promise: promise)
        }^
    }
}
