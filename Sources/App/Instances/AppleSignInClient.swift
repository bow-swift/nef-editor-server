import Foundation
import nef
import Bow
import BowEffects
import AppleSignIn

final class AppleSignInClient: SignInClient {
    
    func signIn(_ request: AppleSignInRequest) -> EnvIO<AppleSignInClientConfig, AppleSignInError, AppleSignInResponse> {
        let applePayload = EnvIO<AppleSignInClientConfig, AppleSignInError, ApplePayload>.var()
        let verifiedPayload = EnvIO<AppleSignInClientConfig, AppleSignInError, ApplePayload>.var()
        let appleToken = EnvIO<AppleSignInClientConfig, AppleSignInError, AppleSignInTokenResponse>.var()
        let response = EnvIO<AppleSignInClientConfig, AppleSignInError, AppleSignInResponse>.var()
        
        return binding(
             applePayload <- self.getPayload(identityToken: request.identityToken),
          verifiedPayload <- self.verify(payload: applePayload.get),
               appleToken <- self.generateAppleToken(code: request.authorizationCode),
                 response <- self.generateBearer(tokenResponse: appleToken.get),
        yield: response.get)^
    }
    
    // MARK: - JWT
    private func getAppleKeys() -> EnvIO<AppleSignInClientConfig, AppleSignInError, JWKSet> {
        AppleSignIn.API.default.getKeys()
            .contramap(\AppleSignInClientConfig.apiConfig)
            .mapError { e in .jwt(.appleKeysNotFound) }
    }
    
    private func getPayload(identityToken jwt: String) -> EnvIO<AppleSignInClientConfig, AppleSignInError, ApplePayload> {
        let jwks = EnvIO<AppleSignInClientConfig, AppleSignInError, JWKSet>.var()
        let payload = EnvIO<AppleSignInClientConfig, AppleSignInError, ApplePayload>.var()
        
        return binding(
               jwks <- self.getAppleKeys(),
            payload <- self.getPayload(identityToken: jwt, jwks: jwks.get),
        yield: payload.get)^
    }
    
    private func getPayload(identityToken: String, jwks: JWKSet) -> EnvIO<AppleSignInClientConfig, AppleSignInError, ApplePayload> {
        EnvIO.invokeResult { _ in
            let signers = jwks.keys.compactMap { key in key.appleSigner }
            return signers.jwtSigners.verifiedPayload(jwt: identityToken)
        }^
    }
    
    private func verify(payload: ApplePayload) -> EnvIO<AppleSignInClientConfig, AppleSignInError, ApplePayload> {
        EnvIO.invoke { env in
            guard payload.issuer == env.environment.appleIssuer else {
                throw AppleSignInError.jwt(.invalidIssuer)
            }
            
            guard payload.audience == env.environment.clientId else {
                throw AppleSignInError.jwt(.invalidClientID)
            }
            
            guard payload.expires > Date() else {
                throw AppleSignInError.jwt(.expiredJWT)
            }
            
            return payload
        }
    }
    
    // MARK: - Generate and validate tokens with Apple
    private func generateAppleToken(code: String) -> EnvIO<AppleSignInClientConfig, AppleSignInError, AppleSignInTokenResponse> {
        let secret = EnvIO<AppleSignInClientConfig, AppleSignInError.AppleTokenError, String>.var()
        let token = EnvIO<AppleSignInClientConfig, AppleSignInError.AppleTokenError, AppleSignInTokenResponse>.var()
        
        return binding(
           secret <- self.clientSecret(),
            token <- self.getToken(clientSecret: secret.get, code: code),
        yield: token.get)^.mapError { e in .invalidAppleToken(e) }^
    }
    
    func getToken(clientSecret: String, code: String) -> EnvIO<AppleSignInClientConfig, AppleSignInError.AppleTokenError, AppleSignInTokenResponse> {
        func appleSignInTokenError(httpError: API.HTTPError) -> EnvIO<AppleSignInClientConfig, AppleSignInError.AppleTokenError, AppleSignInTokenResponse> {
            EnvIO.accessM { env in
                guard let data = httpError.dataError?.data else {
                    return EnvIO.raiseError(.invalidPayload)^
                }
                
                return env.apiConfig.decoder.safeDecode(AppleSignIn.AppleSignInError.self, from: data)
                    .mapError { error in .response(error) }^
                    .flatMap  { response in IO.raiseError(.response(response)) }^
                    .env()^
            }
        }
        
        return EnvIO.accessM { env in
            AppleSignIn.API.default
                .token(clientId: env.environment.clientId,
                       clientSecret: clientSecret,
                       grantType: .authorizationCode,
                       code: code,
                       redirectUri: env.environment.redirectURI)
                .contramap(\AppleSignInClientConfig.apiConfig)
                .flatMapError(appleSignInTokenError)
        }
    }
    
    private func clientSecret(issuedAt: Date = Date()) -> EnvIO<AppleSignInClientConfig, AppleSignInError.AppleTokenError, String> {
        EnvIO.invokeResult { env in
            let expirationDate = issuedAt.addingTimeInterval(env.environment.expirationInterval)
            
            let payload = AppleClientSecretPayload(iss: env.environment.teamId,
                                                   iat: issuedAt,
                                                   exp: expirationDate,
                                                   aud: env.environment.appleIssuer,
                                                   sub: env.environment.clientId)

            return AppleClientSecret(kid: env.environment.keyId, payload: payload)
                .sign(p8key: env.environment.p8Key)
        }
    }
    
    // MARK: - nef server authentication
    private func generateBearer(tokenResponse: AppleSignInTokenResponse) -> EnvIO<AppleSignInClientConfig, AppleSignInError, AppleSignInResponse> {
        let payload = EnvIO<AppleSignInClientConfig, AppleSignInError, AppleTokenPayload>.var()
        
        return binding(
            payload <- self.payload(tokenResponse: tokenResponse),
        yield: .init(token: "dummy-response"))^
        #warning("TODO: from TokenResponse we will create a valid Bearer for authenticated services")
    }
    
    private func payload(tokenResponse: AppleSignInTokenResponse) -> EnvIO<AppleSignInClientConfig, AppleSignInError, AppleTokenPayload> {
        EnvIO.invokeResult { _ in
            AppleTokenPayload.jwtSigners.unverifiedPayload(token: tokenResponse.idToken)
        }
    }
}
