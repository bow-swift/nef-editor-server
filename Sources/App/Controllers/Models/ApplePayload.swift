import Foundation

struct ApplePayload: Codable {
    let issuer: String
    let audience: String
    let expires: Date
    let issuedAt: Date
    let subject: String
    let codeHash: String
    let nonce: Bool
    
    let email: String?
    let emailVerified: String?
    
    enum CodingKeys: String, CodingKey {
        case issuer = "iss"
        case audience = "aud"
        case expires = "exp"
        case issuedAt = "iat"
        case subject = "sub"
        case codeHash = "c_hash"
        case nonce = "nonce_supported"
        case email
        case emailVerified = "email_verified"
    }
}

struct AppleTokenPayload: Codable {
    let issuer: String
    let audience: String
    let expires: Date
    let issuedAt: Date
    let subject: String
    let hash: String
    let authTime: Date
    let nonce: Bool
    
    enum CodingKeys: String, CodingKey {
        case issuer = "iss"
        case audience = "aud"
        case expires = "exp"
        case issuedAt = "iat"
        case subject = "sub"
        case hash = "at_hash"
        case authTime = "auth_time"
        case nonce = "nonce_supported"
    }
}
