import Foundation

enum SignInError: Error {
    case decodingRequest(Error)
    case encodingResponse(Error)
    case invalidUTF8Encoding
    
    case jwt(JWTError)
    case invalidAppleToken(AppleTokenError)
    case bearer(BearerError)
    
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
    
    enum BearerError: Error {
        case encodingRS256Key
        case signing(Error)
        case invalidPayload(Error)
        case invalidIssuer
        case invalidIssuedAt
        case expiredJWT
    }
}
