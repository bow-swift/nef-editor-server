import Vapor
import Bow
import BowEffects

extension WebSocket {
    static func send<C: Encodable>(_ command: C) -> EnvIO<WebSocketConfig, WebSocketError, Void> {
        EnvIO { env in
            let data = IO<WebSocketError, Data>.var()
            
            return binding(
                  data <- env.encoder.safeEncode(command).mapError { e in .encoder(error: e) },
                       |<-env.webSocket.send(data.get),
            yield: ())^
        }
    }
    
    private func send(_ binary: Data) -> IO<WebSocketError, Void> {
        IO.async { callback in
            guard let message = String(data: binary, encoding: .utf8) else {
                callback(.left(WebSocketError.send(data: binary)))
                return
            }
            
            let promise: Promise<Void> = self.eventLoop.newPromise()
            promise.futureResult.whenFailure { error in
                callback(.left(WebSocketError.send(error: error)))
            }
            promise.futureResult.whenSuccess {
                callback(.right(()))
            }
            
            self.send(message, promise: promise)
        }^
    }
}
