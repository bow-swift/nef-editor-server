import Foundation

struct AppleJWT: Codable {
    let issuer: String
    let audience: String
    let expires: Date
    let issuedAt: Date
    let subject: String
    let nonce: Bool
    
    let email: String?
    let emailVerified: String?
    
    enum CodingKeys: String, CodingKey {
        case email
        case issuer = "iss"
        case audience = "aud"
        case expires = "exp"
        case issuedAt = "iat"
        case subject = "sub"
        case nonce = "nonce_supported"
        case emailVerified = "email_verified"
    }
}
