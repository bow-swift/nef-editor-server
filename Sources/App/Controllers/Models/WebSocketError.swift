import Foundation

enum WebSocketError: Error {
    case encoder(error: Error)
    case decoder(error: Error)
    case decoder(text: String)
    case send(error: Error)
    case send(data: Data)
}
