import Foundation
import AppleSignIn

struct SignInConfig {
    let apiConfig: API.Config
    let environment: SignInEnvironment
    let responseEncoder: JSONEncoder
}
