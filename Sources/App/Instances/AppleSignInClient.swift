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
                     |<-self.verify(appleJWT: appleJWT.get, request: request),
        yield: AppleSignInResponse(token: "dummy response"))^
    }
    
    // MARK: - JWT
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
            .mapError { e in AppleSignInError.jwt(e) }
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
    
    private func verify(appleJWT: AppleJWT, request: AppleSignInRequest) -> EnvIO<API.Config, AppleSignInError, Void> {
        guard appleJWT.issuer == "https://appleid.apple.com" else {
            return EnvIO.raiseError(AppleSignInError.jwtVerification(info: "invalid issuer"))^
        }
        
        guard appleJWT.subject == request.user else {
            return EnvIO.raiseError(AppleSignInError.jwtVerification(info: "invalid user ID"))^
        }
        
        guard appleJWT.expires > Date() else {
            return EnvIO.raiseError(AppleSignInError.jwtVerification(info: "expiration date"))^
        }
        
        return EnvIO.pure(())^
    }
}
