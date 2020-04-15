import Foundation

struct AppleSignInRequest: Codable {
    let user: String
    let identityToken: String
    let authorizationCode: String
}

struct AppleSignInResponse: Codable {
    let token: String
}
