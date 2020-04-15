import Foundation

enum AppleSignInError: Error {
    case decoding(Error? = nil)
    case encoding(Error? = nil)
    case jwt(Error)
    case jwtVerification(info: String)
}

extension AppleSignInError: CustomStringConvertible {
    var description: String {
        switch self {
        case .decoding(let e):
            if let e = e {
                return "\(e)"
            } else {
                return "The decode operation could not be completed"
            }
        case .encoding(let e):
            if let e = e {
                return "\(e)"
            } else {
                return "the encode operation could not be completed"
            }
        case .jwt(let e):
            return "Could not validate JWT: \(e)"
        case .jwtVerification(let info):
            return "Received an invalid JWT: \(info)"
        }
    }
}
