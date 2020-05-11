import Foundation

enum SignInError: Error {
    case invalidCodification(CodificationError)
    case jwt(JWTError)
    case appleToken(AppleTokenError)
    case bearer(BearerError)
}

extension SignInError: CustomStringConvertible {
    var description: String {
        switch self {
        case .invalidCodification(let error): return "\(error)"
        case .jwt(let error): return "JWT: \(error)"
        case .appleToken(let error): return "Apple Token: \(error)"
        case .bearer(let error): return "Bearer: \(error)"
        }
    }
}
