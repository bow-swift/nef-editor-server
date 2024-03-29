import Foundation
import Bow
import BowEffects

protocol HasWebSocketOutput {
    var webSocket: WebSocketOutput { get }
}

protocol WebSocketOutput {
    func send<D>(binary: Data) -> EnvIO<D, WebSocketError, Void>
}

extension WebSocketOutput {
    func send<C: Encodable, D: HasCommandEncoder>(command: C) -> EnvIO<D, WebSocketError, Void> {
        let encoder = EnvIO<D, WebSocketError, D>.var()
        let data = EnvIO<D, WebSocketError, Data>.var()
        
        return binding(
           encoder <- .ask(),
              data <- encoder.get.commandEncoder.safeEncode(command).mapError { e in .encoding(error: e) },
                   |<-self.send(binary: data.get),
        yield: ())^
    }
}
