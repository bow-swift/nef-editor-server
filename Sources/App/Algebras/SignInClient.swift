import Vapor
import BowEffects
import NefEditorData
import AppleSignIn

protocol SignInClient {
    func signIn(_ request: AppleSignInRequest) -> EnvIO<API.Config, AppleSignInError, AppleSignInResponse>
}
