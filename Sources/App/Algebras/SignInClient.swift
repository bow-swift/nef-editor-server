import Vapor
import BowEffects
import NefEditorData
import AppleSignIn

protocol SignInClient {
    func signIn() -> EnvIO<API.Config, AppleSignInError, AppleSignInResponse>
}
