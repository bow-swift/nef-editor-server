import Vapor
import nef
import Bow
import BowEffects
import NefEditorData

final class AppleSignInServer: AppleSignIn {
    
    func signIn() -> EnvIO<Request, AppleSignInError, AppleSignInResponse> {
        fatalError()
    }
}
