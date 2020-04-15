import Vapor
import nef
import Bow
import BowEffects
import NefEditorData
import AppleSignIn

final class AppleSignInClient: SignInClient {
    
    func signIn() -> EnvIO<API.Config, AppleSignInError, AppleSignInResponse> {
        let keys = EnvIO<API.Config, AppleSignInError, JWKSet>.var()
        
        return binding(
                keys <- self.getAppleKeys(),
        yield: AppleSignInResponse(token: "dummy response"))^
    }
    
    private func getAppleKeys() -> EnvIO<API.Config, AppleSignInError, JWKSet> {
        AppleSignIn.API.default.getKeys()
            .mapError { e in AppleSignInError.request(e) }
    }
}
