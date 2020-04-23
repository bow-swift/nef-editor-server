import BowEffects
import NefEditorData
import AppleSignIn

protocol SignInClient {
    func signIn(_ request: AppleSignInRequest) -> EnvIO<AppleSignInClientConfig, SignInError, AppleSignInResponse>
}
