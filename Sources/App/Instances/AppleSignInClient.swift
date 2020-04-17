import Foundation
import nef
import Bow
import BowEffects
import AppleSignIn

final class AppleSignInClient: SignInClient {
    private let decoder: Decoder
    
    init(decoder: Decoder) {
        self.decoder = decoder
    }
    
    func signIn(_ request: AppleSignInRequest) -> EnvIO<API.Config, AppleSignInError, AppleSignInResponse> {
        let appleJWT = EnvIO<API.Config, AppleSignInError, AppleJWT>.var()
        let secret = EnvIO<API.Config, AppleSignInError, String>.var()
        let token = EnvIO<API.Config, AppleSignInError, AppleSignInResponse>.var()
        
        return binding(
          appleJWT <- self.decode(identityToken: request.identityToken),
                   |<-self.verify(appleJWT: appleJWT.get, request: request),
            secret <- self.clientSecret(appleJWT: appleJWT.get),
             token <- self.generateAppleToken(clientId: appleJWT.get.audience, clientSecret: secret.get, code: request.authorizationCode),
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
        guard appleJWT.issuer == SignIn.appleIssuer else {
            return EnvIO.raiseError(.jwt(.invalidIssuer))^
        }
        
        guard appleJWT.subject == request.user else {
            return EnvIO.raiseError(.jwt(.invalidUserID))^
        }
        
        guard appleJWT.audience == SignIn.clientId else {
            return EnvIO.raiseError(.jwt(.invalidClientID))^
        }
        
        guard appleJWT.expires > Date() else {
            return EnvIO.raiseError(.jwt(.expiredJWT))^
        }
        
        return EnvIO.pure(())^
    }
    
    // MARK: - Generate and validate tokens with Apple
    private func clientSecret(appleJWT: AppleJWT) -> EnvIO<API.Config, AppleSignInError, String> {
        fatalError()
    }
    
    private func generateAppleToken(clientId: String, clientSecret: String, code: String) -> EnvIO<API.Config, AppleSignInError, AppleSignInResponse> {
        let getToken = AppleSignIn.API.default.token(clientId: clientId,
                                                     clientSecret: clientSecret,
                                                     grantType: .authorizationCode,
                                                     code: code,
                                                     redirectUri: SignIn.redirectURI)

        return getToken
            .map(\.idToken)
            .map(AppleSignInResponse.init)^
            .flatMapError { httpError in
                guard let data = httpError.dataError?.data else {
                    return EnvIO.raiseError(.signIn(info: "\(httpError.error)"))^
                }
                
                return self.decoder.safeDecode(AppleSignIn.AppleSignInError.self, from: data)
                    .mapError { error in .signIn(info: "\(error)") }^
                    .flatMap  { response in EnvIO.raiseError(.signIn(info: "\(response)"))^ }^
            }
    }
    
    // MARK: - Constants
    enum SignIn {
        static let appleIssuer = "https://appleid.apple.com"
        static let teamId = "PKCNK63FZQ"
        static let keyId = "J9CD6BW6MF"
        static let clientId = "com.47deg.SignInAppleTest"
        static let redirectURI = "https://signin.etsiit.es/redirect"
    }
}
