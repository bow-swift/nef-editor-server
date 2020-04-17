import Foundation

enum AppleSignInError: Error {
    case decodingRequest(Error)
    case encodingResponse(Error)
    case invalidUTF8Encoding
    case appleKeysNotFound
    case jwt(JWT)
    
    enum JWT: Error {
        case decrypt(Error)
        case invalidClientID
        case invalidIssuer
        case invalidUserID
        case expiredJWT
    }
}
