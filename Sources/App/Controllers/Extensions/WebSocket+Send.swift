import Vapor
import Bow
import BowEffects

extension WebSocket {
    
    static func send<C: Encodable>(_ command: C) -> EnvIO<WebSocketConfig, WebSocketError, Void> {
        EnvIO { env in
            let data = IO<WebSocketError, Data>.var()
            let output = IO<WebSocketError, Void>.var()
            
            return binding(
                  data <- env.encoder.safeEncode(command).mapError { e in .encoder(e) },
                output <- env.webSocket.send(data.get),
            yield: output.get)^
        }
    }
    
    private func send(_ binary: Data) -> IO<WebSocketError, Void> {
        IO.async { callback in
            let promise: Promise<Void> = self.eventLoop.newPromise()
            promise.futureResult.whenFailure { error in callback(.left(WebSocketError.send(error)))}
            promise.futureResult.whenSuccess { callback(.right(())) }
            
            self.send(binary, promise: promise)
        }^
    }
}
