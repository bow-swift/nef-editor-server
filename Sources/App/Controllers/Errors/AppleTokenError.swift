import Foundation

enum AppleTokenError: Error {
    case invalidPayload
    case encodingP8Key
    case clientSecret(Error)
    case response(Error)
}
