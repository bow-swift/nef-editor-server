import Foundation
import Bow
import BowEffects

protocol WebSocketOutput {
    func send<D>(binary: Data) -> EnvIO<D, WebSocketError, Void>
}

protocol WebSocketCommandOutput {
    func send<C: Encodable>(command: C) -> EnvIO<WebSocketConfig, WebSocketError, Void>
}

extension WebSocketCommandOutput {
    func send<C: Encodable>(command: C) -> EnvIO<WebSocketConfig, WebSocketError, Void> {
        let data = EnvIO<WebSocketConfig, WebSocketError, Data>.var()
        let env = EnvIO<WebSocketConfig, WebSocketError, WebSocketConfig>.var()
        
        return binding(
               env <- .ask(),
              data <- env.get.encoder.safeEncode(command).mapError { e in WebSocketError.encoding(error: e) }.env(),
                   |<-env.get.webSocket.send(binary: data.get),
        yield: ())^
    }
}
