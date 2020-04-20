import Foundation
import nef
import Bow
import BowEffects
import AppleSignIn

import JWTKit

final class AppleSignInClient: SignInClient {
    
    func signIn(_ request: AppleSignInRequest) -> EnvIO<API.Config, AppleSignInError, AppleSignInResponse> {
        let appleJWT = EnvIO<API.Config, AppleSignInError, AppleJWT>.var()
        let verifiedJWT = EnvIO<API.Config, AppleSignInError, AppleJWT>.var()
        let secret = EnvIO<API.Config, AppleSignInError, String>.var()
        let appleToken = EnvIO<API.Config, AppleSignInError, AppleSignInTokenResponse>.var()
        let response = EnvIO<API.Config, AppleSignInError, AppleSignInResponse>.var()
        
        return binding(
             appleJWT <- self.decode(identityToken: request.identityToken),
          verifiedJWT <- self.verify(appleJWT: appleJWT.get, request: request),
               secret <- self.clientSecret(teamId: SignIn.teamId, clientId: verifiedJWT.get.audience),
           appleToken <- self.generateAppleToken(clientId: verifiedJWT.get.audience, clientSecret: secret.get, code: request.authorizationCode),
             response <- self.generateBearer(tokenResponse: appleToken.get, expirationInterval: SignIn.expirationInterval),
        yield: response.get)^
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
            .mapError { e in .jwt(.appleKeysNotFound) }
    }
    
    private func decode(identityToken: String, jwks: JWKSet) -> EnvIO<API.Config, AppleSignInError, AppleJWT> {
        EnvIO.invokeResult { _ in
            let signers = jwks.keys.compactMap { key in key.appleSigner }
            return signers.decode(jwt: identityToken)
        }^
    }
    
    private func verify(appleJWT: AppleJWT, request: AppleSignInRequest) -> EnvIO<API.Config, AppleSignInError, AppleJWT> {
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
        
        return EnvIO.pure(appleJWT)^
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
                    return EnvIO.raiseError(.invalidAppleJWT)^
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
        let payload = EnvIO<API.Config, AppleSignInError, AppleTokenJWT>.var()
        
        return binding(
            payload <- self.payload(tokenResponse: tokenResponse),
        yield: .init(token: "dummy-response"))^
        #warning("TODO: from TokenResponse we will create a valid Bearer for authenticated services")
    }
    
    private func payload(tokenResponse: AppleSignInTokenResponse) -> EnvIO<API.Config, AppleSignInError, AppleTokenJWT> {
        EnvIO.invokeResult { _ in
            AppleTokenJWT.unverifiedPayload(token: tokenResponse.idToken)
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
