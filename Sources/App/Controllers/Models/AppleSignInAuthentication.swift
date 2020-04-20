import Foundation

struct AppleSignInRequest: Codable {
    let identityToken: String
    let authorizationCode: String
}

struct AppleSignInResponse: Codable {
    let token: String
}
