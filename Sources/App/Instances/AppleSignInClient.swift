import Foundation
import nef
import Bow
import BowEffects
import AppleSignIn

final class AppleSignInClient: SignInClient {
    
    func signIn(_ request: AppleSignInRequest) -> EnvIO<API.Config, AppleSignInError, AppleSignInResponse> {
        let applePayload = EnvIO<API.Config, AppleSignInError, ApplePayload>.var()
        let verifiedPayload = EnvIO<API.Config, AppleSignInError, ApplePayload>.var()
        let secretJWT = EnvIO<API.Config, AppleSignInError, String>.var()
        let appleToken = EnvIO<API.Config, AppleSignInError, AppleSignInTokenResponse>.var()
        let response = EnvIO<API.Config, AppleSignInError, AppleSignInResponse>.var()
        
        return binding(
             applePayload <- self.getPayload(identityToken: request.identityToken),
          verifiedPayload <- self.verify(payload: applePayload.get),
                secretJWT <- self.clientSecret(teamId: SignIn.teamId, clientId: verifiedPayload.get.audience),
               appleToken <- self.generateAppleToken(clientId: verifiedPayload.get.audience, clientSecret: secretJWT.get, code: request.authorizationCode),
                 response <- self.generateBearer(tokenResponse: appleToken.get, expirationInterval: SignIn.expirationInterval),
        yield: response.get)^
    }
    
    // MARK: - JWT
    private func getAppleKeys() -> EnvIO<API.Config, AppleSignInError, JWKSet> {
        AppleSignIn.API.default.getKeys()
            .mapError { e in .jwt(.appleKeysNotFound) }
    }
    
    private func getPayload(identityToken jwt: String) -> EnvIO<API.Config, AppleSignInError, ApplePayload> {
        let jwks = EnvIO<API.Config, AppleSignInError, JWKSet>.var()
        let payload = EnvIO<API.Config, AppleSignInError, ApplePayload>.var()
        
        return binding(
               jwks <- self.getAppleKeys(),
            payload <- self.getPayload(identityToken: jwt, jwks: jwks.get),
        yield: payload.get)^
    }
    
    private func getPayload(identityToken: String, jwks: JWKSet) -> EnvIO<API.Config, AppleSignInError, ApplePayload> {
        EnvIO.invokeResult { _ in
            let signers = jwks.keys.compactMap { key in key.appleSigner }
            return signers.jwtSigners.verifiedPayload(jwt: identityToken)
        }^
    }
    
    private func verify(payload: ApplePayload) -> EnvIO<API.Config, AppleSignInError, ApplePayload> {
        guard payload.issuer == SignIn.appleIssuer else {
            return EnvIO.raiseError(.jwt(.invalidIssuer))^
        }
        
        guard payload.audience == SignIn.clientId else {
            return EnvIO.raiseError(.jwt(.invalidClientID))^
        }
        
        guard payload.expires > Date() else {
            return EnvIO.raiseError(.jwt(.expiredJWT))^
        }
        
        return EnvIO.pure(payload)^
    }
    
    // MARK: - Generate and validate tokens with Apple
    private func clientSecret(teamId: String, clientId: String) -> EnvIO<API.Config, AppleSignInError, String> {
        EnvIO.invokeResult { _ in
            let currentDate = Date()
            let currentDateAdding24H = currentDate.addingTimeInterval(24*60*60)
            
            let payload = AppleClientSecretPayload(iss: teamId,
                                                   iat: currentDate,
                                                   exp: currentDateAdding24H,
                                                   aud: SignIn.appleIssuer,
                                                   sub: clientId)

            return AppleClientSecret(kid: SignIn.keyId, payload: payload)
                .sign(p8key: SignIn.p8Key)
                .mapError { e in .appleToken(e) }
        }
    }
    
    private func generateAppleToken(clientId: String, clientSecret: String, code: String) -> EnvIO<API.Config, AppleSignInError, AppleSignInTokenResponse> {
        func appleSignInTokenError(httpError: API.HTTPError) -> EnvIO<API.Config, AppleSignInError.AppleToken, AppleSignInTokenResponse> {
            EnvIO.accessM { env in
                guard let data = httpError.dataError?.data else {
                    return EnvIO.raiseError(.invalidPayload)^
                }
                
                return env.decoder.safeDecode(AppleSignIn.AppleSignInError.self, from: data)
                    .mapError { error in .response(error) }^
                    .flatMap  { response in IO.raiseError(.response(response)) }^
                    .env()^
            }
        }
        
        let getToken = AppleSignIn.API.default.token(clientId: clientId,
                                                     clientSecret: clientSecret,
                                                     grantType: .authorizationCode,
                                                     code: code,
                                                     redirectUri: SignIn.redirectURI)
        return getToken
            .flatMapError(appleSignInTokenError)^
            .mapError { e in .appleToken(e) }^
    }
    
    // MARK: - nef server authentication
    private func generateBearer(tokenResponse: AppleSignInTokenResponse, expirationInterval: TimeInterval) -> EnvIO<API.Config, AppleSignInError, AppleSignInResponse> {
        let payload = EnvIO<API.Config, AppleSignInError, AppleTokenPayload>.var()
        
        return binding(
            payload <- self.payload(tokenResponse: tokenResponse),
        yield: .init(token: "dummy-response"))^
        #warning("TODO: from TokenResponse we will create a valid Bearer for authenticated services")
    }
    
    private func payload(tokenResponse: AppleSignInTokenResponse) -> EnvIO<API.Config, AppleSignInError, AppleTokenPayload> {
        EnvIO.invokeResult { _ in
            AppleTokenPayload.jwtSigners.unverifiedPayload(token: tokenResponse.idToken)
        }
    }
    
    
    // MARK: - Constants
    #warning("TODO: when we will create an identifier/servicesId/keys in the WWDC portal we will fill with real data")
    enum SignIn {
        static let appleIssuer = "https://appleid.apple.com"
        static let teamId = "PKCNK63FZQ"
        static let keyId = "J9CD6BW6MF"
        static let clientId = "com.47deg.SignInAppleTest"
        static let redirectURI = "https://signin.etsiit.es/redirect"
        static let expirationInterval: TimeInterval = 24*60*60
        static let p8Key = "-"
    }
}
