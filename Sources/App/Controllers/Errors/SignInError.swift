import Foundation

enum SignInError: Error {
    case decodingRequest(Error)
    case encodingResponse(Error)
    case invalidUTF8Encoding
    
    case jwt(JWTError)
    case appleToken(AppleTokenError)
    case bearer(BearerError)
}
