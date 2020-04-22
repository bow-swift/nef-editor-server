import Foundation

struct SignInEnvironment {
    let signIn: AppleSignInEnvironment
    let bearer: BearerEnvironment
}

struct AppleSignInEnvironment {
    let p8Key: String
    let teamId: String
    let keyId: String
    let clientId: String
    let redirectURI: String
    let issuer = "https://appleid.apple.com"
}

struct BearerEnvironment {
    let privateKey: String
    let publicKey: String
    let expirationInterval: TimeInterval = 24*60*60 // 24H
    let issuer = "com.47deg.nef-editor-server"
}
