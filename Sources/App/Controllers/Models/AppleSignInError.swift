import Foundation

enum AppleSignInError: Error {
    case decodingRequest(Error)
    case encodingResponse(Error)
    case invalidUTF8Encoding
    
    case jwt(JWT)
    case appleToken(AppleToken)
    
    enum JWT: Error {
        case appleKeysNotFound
        case decrypt(Error)
        case invalidClientID
        case invalidIssuer
        case invalidUserID
        case expiredJWT
    }
    
    enum AppleToken: Error {
        case invalidAppleJWT
        case encodingP8Key
        case clientSecret(Error)
        case response(Error)
    }
}
