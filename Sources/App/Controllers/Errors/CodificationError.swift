import Foundation

enum CodificationError: Error {
    case decodingRequest(Error)
    case encodingResponse(Error)
    case invalidUTF8Encoding
}
