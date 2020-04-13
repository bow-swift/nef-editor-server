import Vapor
import BowEffects
import NefEditorData

protocol AppleSignIn {
    func signIn() -> EnvIO<Request, AppleSignInError, AppleSignInResponse>
}
