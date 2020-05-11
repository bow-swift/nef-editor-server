import Foundation

enum WebSocketError: Error {
    case encoding(error: Error)
    case utf8Expected
    case decoding(error: Error)
    case decoding(text: String)
    case sending(error: Error)
    case sending(data: Data)
}
