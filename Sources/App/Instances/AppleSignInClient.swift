import Foundation
import nef
import Bow
import BowEffects
import AppleSignIn


final class AppleSignInClient: SignInClient {
    
    func signIn(_ request: AppleSignInRequest) -> EnvIO<API.Config, AppleSignInError, AppleSignInResponse> {
        let appleJWT = EnvIO<API.Config, AppleSignInError, AppleJWT>.var()
        let token = EnvIO<API.Config, AppleSignInError, AppleSignInResponse>.var()
        
        return binding(
            appleJWT <- self.decode(identityToken: request.identityToken),
                     |<-self.verify(appleJWT: appleJWT.get, request: request),
               token <- self.generateAppleToken(appleJWT: appleJWT.get),
        yield: token.get)^
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
            .mapError { e in AppleSignInError.appleKeysNotFound }
    }
    
    private func decode(identityToken: String, jwks: JWKSet) -> EnvIO<API.Config, AppleSignInError, AppleJWT> {
        EnvIO.invokeResult { _ in
            let signers = jwks.keys.compactMap { key in key.appleSigner }
            return signers.decode(jwt: identityToken)
        }^
    }
    
    private func verify(appleJWT: AppleJWT, request: AppleSignInRequest) -> EnvIO<API.Config, AppleSignInError, Void> {
        guard appleJWT.issuer == Constants.appleIssuer else {
            return EnvIO.raiseError(.jwt(.invalidIssuer))^
        }
        
        guard appleJWT.subject == request.user else {
            return EnvIO.raiseError(.jwt(.invalidUserID))^
        }
        
        guard appleJWT.audience == Constants.clientBundleId else {
            return EnvIO.raiseError(.jwt(.invalidClientID))^
        }
        
        guard appleJWT.expires > Date() else {
            return EnvIO.raiseError(.jwt(.expiredJWT))^
        }
        
        return EnvIO.pure(())^
    }
    
    // MARK: - Generate and validate tokens with Apple
    private func generateAppleToken(appleJWT: AppleJWT) -> EnvIO<API.Config, AppleSignInError, AppleSignInResponse> {
        fatalError()
    }
    
    // MARK: - Constants
    #warning("TODO: when we will create an identifier/servicesId/keys in the WWDC portal we will fill with real data")
    enum Constants {
        static let appleIssuer = "https://appleid.apple.com"
        static let clientBundleId = "com.47deg.SignInAppleTest"
    }
}
