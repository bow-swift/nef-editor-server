import Foundation
import Bow
import BowEffects

protocol WebSocketOutput {
    func send<D>(binary: Data) -> EnvIO<D, WebSocketError, Void>
}
