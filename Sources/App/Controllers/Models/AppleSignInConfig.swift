import Foundation
import AppleSignIn

struct AppleSignInConfig {
    let client: SignInClient
    let clientConfig: AppleSignInClientConfig
    let responseEncoder: JSONEncoder
}

struct AppleSignInClientConfig {
    let apiConfig: API.Config
    let environment: SignInEnvironment
}
