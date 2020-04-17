import Foundation
import AppleSignIn

struct AppleSignInConfig {
    let client: SignInClient
    let apiConfig: API.Config
    let responseEncoder: JSONEncoder
}
