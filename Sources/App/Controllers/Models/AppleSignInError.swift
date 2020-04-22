import Foundation

enum AppleSignInError: Error {
    case decodingRequest(Error)
    case encodingResponse(Error)
    case invalidUTF8Encoding
    
    case jwt(JWTError)
    case invalidAppleToken(AppleTokenError)
    
    enum JWTError: Error {
        case appleKeysNotFound
        case decrypt(Error)
        case invalidClientID
        case invalidIssuer
        case invalidUserID
        case expiredJWT
    }
    
    enum AppleTokenError: Error {
        case invalidPayload
        case encodingP8Key
        case clientSecret(Error)
        case response(Error)
    }
}
