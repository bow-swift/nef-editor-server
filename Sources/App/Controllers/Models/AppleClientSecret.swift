import Foundation

struct AppleClientSecretPayload: Codable {
    let iss: String
    let iat: Date
    let exp: Date
    let aud: String
    let sub: String
}

struct AppleClientSecret: Codable {
    let kid: String
    let payload: AppleClientSecretPayload
}
