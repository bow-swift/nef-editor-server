import Foundation

enum WebSocketError: Error {
    case encoder(Error)
    case decoder(Error)
    case decoder(text: String)
    case send(Error)
}
