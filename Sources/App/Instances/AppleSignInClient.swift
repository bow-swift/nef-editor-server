import Vapor
import nef
import Bow
import BowEffects

import NefEditorData
import AppleSignIn


final class AppleSignInClient: SignInClient {
    
    func signIn(_ request: AppleSignInRequest) -> EnvIO<API.Config, AppleSignInError, AppleSignInResponse> {
        let appleJWT = EnvIO<API.Config, AppleSignInError, AppleJWT>.var()
        
        return binding(
            appleJWT <- self.decode(identityToken: request.identityToken),
        yield: AppleSignInResponse(token: "dummy response"))^
    }
    
    private func decode(identityToken jwt: String) -> EnvIO<API.Config, AppleSignInError, AppleJWT> {
        let jwks = EnvIO<API.Config, AppleSignInError, JWKSet>.var()
        let appleJWT = EnvIO<API.Config, AppleSignInError, AppleJWT>.var()
        
        return binding(
                jwks <- self.getAppleKeys(),
            appleJWT <- self.decode(identityToken: jwt, jwks: jwks.get),
        yield: appleJWT.get)^
    }
    
    private func getAppleKeys() -> EnvIO<API.Config, AppleSignInError, JWKSet> {
        AppleSignIn.API.default.getKeys()
            .mapError { e in AppleSignInError.request(e) }
    }
    
    private func decode(identityToken: String, jwks: JWKSet) -> EnvIO<API.Config, AppleSignInError, AppleJWT> {
        let signers = jwks.keys.compactMap { key in key.appleSigner }
        
        do {
            let appleJWT = try signers.decode(jwt: identityToken)
            return EnvIO.pure(appleJWT)^
        } catch {
            return EnvIO.raiseError(AppleSignInError.jwt(error))^
        }
    }
}
