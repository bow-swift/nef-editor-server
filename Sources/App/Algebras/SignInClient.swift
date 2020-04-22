import Vapor
import BowEffects
import NefEditorData
import AppleSignIn

protocol SignInClient {
    func signIn(_ request: AppleSignInRequest) -> EnvIO<AppleSignInClientConfig, SignInError, AppleSignInResponse>
    func verify(_ bearer: String) -> EnvIO<BearerEnvironment, SignInError.BearerError, BearerPayload>
}
