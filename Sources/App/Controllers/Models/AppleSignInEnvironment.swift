import Foundation

struct AppleSignInEnvironment {
    let p8Key: String
    let teamId: String
    let keyId: String
    let clientId: String
    let redirectURI: String
    
    let appleIssuer: String = "https://appleid.apple.com"
    let expirationInterval: TimeInterval = 24*60*60
}
