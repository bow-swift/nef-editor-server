import Foundation

public struct AppleSignInRequest: Codable {
    public let user: String
    public let identityToken: String
    public let authorizationCode: String
    
    public init(user: String, identityToken: String, authorizationCode: String) {
        self.user = user
        self.identityToken = identityToken
        self.authorizationCode = authorizationCode
    }
}

public struct AppleSignInResponse: Codable {
    public let token: String
    
    public init(token: String) {
        self.token = token
    }
}
