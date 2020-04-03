import Foundation
import Bow
import BowEffects

protocol HasWebSocketOutput {
    var webSocket: WebSocketOutput { get }
}

protocol WebSocketOutput {
    func send<D>(binary: Data) -> EnvIO<D, WebSocketError, Void>
    func send<C: Encodable>(command: C) -> EnvIO<HasCommandEncoder, WebSocketError, Void>
}

extension WebSocketOutput {
    func send<C: Encodable>(command: C) -> EnvIO<HasCommandEncoder, WebSocketError, Void> {
        let encoder = EnvIO<HasCommandEncoder, WebSocketError, HasCommandEncoder>.var()
        let data = EnvIO<HasCommandEncoder, WebSocketError, Data>.var()
        
        return binding(
           encoder <- .ask(),
              data <- encoder.get.commandEncoder.safeEncode(command).mapError { e in WebSocketError.encoding(error: e) },
                   |<-self.send(binary: data.get),
        yield: ())^
    }
}
