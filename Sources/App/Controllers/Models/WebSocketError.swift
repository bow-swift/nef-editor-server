import Foundation

enum WebSocketError: Error {
    case encoder(Error)
    case send(Error)
}
