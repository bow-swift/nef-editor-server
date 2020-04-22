import Foundation

enum SignInError: Error {
    case invalidCodification(CodificationError)
    case jwt(JWTError)
    case appleToken(AppleTokenError)
    case bearer(BearerError)
}
