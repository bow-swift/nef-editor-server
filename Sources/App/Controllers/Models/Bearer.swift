import Foundation

struct BearerPayload: Codable {
    let issuer: String
    let subject: String
    let issuedAt: Date
    let expires: Date
    
    enum CodingKeys: String, CodingKey {
        case issuer = "iss"
        case subject = "sub"
        case issuedAt = "iat"
        case expires = "exp"
    }
}

struct Bearer: Codable {
    let payload: BearerPayload
}
