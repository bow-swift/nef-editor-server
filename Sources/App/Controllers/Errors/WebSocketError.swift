import Foundation

enum WebSocketError: Error {
    case encoding(error: Error)
    case encodingUTF8
    case decoding(error: Error)
    case decoding(text: String)
    case sending(error: Error)
    case sending(data: Data)
}
